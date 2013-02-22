require 'spec_helper'
require 'set'
require 'accord/specification'

module Accord
  describe Specification do
    describe "empty specification" do
      let(:spec) { Specification.new }
      it "has only itself as its ancestor" do
        expect(spec.ancestors).to eq [spec]
      end

      it "extends itself" do
        expect(spec).to be_extends(spec)
      end
    end

    describe "specification based on another" do
      let(:base_spec) { Specification.new }
      let(:spec)      { Specification.new([base_spec]) }

      it "has itself as and its base specification as ancestors" do
        expect(Set.new(spec.ancestors)).to eq Set.new([spec, base_spec])
      end

      it "extends itself" do
        expect(spec).to be_extends(spec)
      end

      it "extends the base specification" do
        expect(spec).to be_extends(base_spec)
      end
    end

    describe "specification ancestry ordering" do
      # Note that spec ancestors are not sorted like Ruby's module ancestors.
      #
      # The expected results should match the C3 algorithm.  For more
      # information, refer to the MRO used in Python (introduced in Python
      # 2.3): http://www.python.org/download/releases/2.3/mro/

      let(:root) { Specification.new(:root) }

      describe "impossible" do
        let(:a) { Specification.new([root]) }
        let(:b) { Specification.new([a, root]) }
        let(:c) { Specification.new([root]) }
        let(:d) { Specification.new([b, c]) }
        # let(:s5) { Specification.new([c, b, d]) } # This should break

        it "rejects such hierarchy" do
          # This hierarchy is rejected because local order prececedence cannot
          # be satisfied without violating monotonicity.
          expect { Specification.new([c, b, d]) }.to raise_error(TypeError)
        end
      end

      describe "possible" do
        let(:a) { Specification.new(:a, [root]) }
        let(:b) { Specification.new(:b, [root]) }
        let(:c) { Specification.new(:c, [root]) }
        let(:d) { Specification.new(:d, [c, a]) }
        let(:e) { Specification.new(:e, [c, b]) }
        let(:f) { Specification.new(:f, [e, d]) }

        let(:expected_resolution_order) { [f, e, d, c, b, a, root] }

        subject { f }
        its(:ancestors) { should eq expected_resolution_order }
      end

      describe "possible" do
        let(:a) { Specification.new(:a, [root]) }
        let(:b) { Specification.new(:b, [root]) }
        let(:c) { Specification.new(:c, [root]) }
        let(:d) { Specification.new(:d, [c, a]) }
        let(:e) { Specification.new(:e, [b, c]) }
        let(:f) { Specification.new(:f, [e, d]) }

        let(:expected_resolution_order) { [f, e, b, d, c, a, root] }

        subject { f }
        its(:ancestors) { should eq expected_resolution_order }
      end

      describe "possible" do
        let(:a)  { Specification.new(:a,  [root]) }
        let(:b)  { Specification.new(:b,  [root]) }
        let(:c)  { Specification.new(:c,  [root]) }
        let(:d)  { Specification.new(:d,  [root]) }
        let(:e)  { Specification.new(:e,  [root]) }
        let(:k1) { Specification.new(:k1, [a, b, c]) }
        let(:k2) { Specification.new(:k2, [d, b, e]) }
        let(:k3) { Specification.new(:k3, [d, a]) }
        let(:z)  { Specification.new(:z,  [k1, k2, k3]) }

        let(:expected_resolution_order) do
          [z, k1, k2, k3, d, a, b, c, e, root]
        end

        subject { z }
        its(:ancestors) { should eq expected_resolution_order }
      end
    end

    describe "bad bases" do
      context "on construction" do
        it "complains if something other than Specification is set as a base" do
          expect { Specification.new(['bad']) }.to raise_error(TypeError)
        end
      end

      context "on #bases=" do
        let(:spec) { Specification.new }

        it "complains if set to not an array of Specification's" do
          expect { spec.bases = ['bad'] }.to raise_error(TypeError)
        end
      end
    end

    describe "bases change" do
      let(:spec)           { Specification.new }
      let(:dependent_spec) { Specification.new([spec]) }

      it "updates ancestry in dependent specifications" do
        base = Specification.new
        spec.bases = [base]

        expect(dependent_spec.ancestors).to eq [dependent_spec, spec, base]
      end

      it "updates ancestry in dependent specs if base change in ancestor" do
        base1 = Specification.new
        base2 = Specification.new([base1])
        spec.bases = [base2]

        base2.bases = []

        expect(spec.ancestors).to eq [spec, base2]
      end

      it "makes old bases to not be extended by old dependent" do
        old_base = Specification.new
        new_base = Specification.new
        spec.bases = [old_base]

        spec.bases = [new_base]

        expect(spec).to_not be_extends(old_base)
      end

      it "can leave no base" do
        base = Specification.new
        spec.bases = [base]

        spec.bases = []

        expect(spec.ancestors).to eq [spec]
      end

      it "can add bases" do
        base1 = Specification.new
        base2 = Specification.new
        spec.bases = [base1]

        spec.bases = [base1, base2]

        expect(spec.ancestors).to eq [spec, base1, base2]
      end

      it "leaves other dependents untouched" do
        base = Specification.new
        spec.bases = [base]
        other_spec = Specification.new([base])

        spec.bases = []
        expect(other_spec.ancestors).to include(base)
      end

      it "cannot modify ancestors through modifying returned bases directly" do
        base = Specification.new
        spec.bases << base

        expect(spec.ancestors).to eq [spec]
      end
    end

    describe "#interfaces" do
      it "is empty by default" do
        expect(Specification.new.interfaces).to be_empty
      end

      it "is empty when dealing only with pure specifications" do
        base = Specification.new
        spec = Specification.new([base])
        expect(spec.interfaces).to be_empty
      end

      it "takes interfaces from bases through #each_interface" do
        interface1 = stub(:i1)
        interface2 = stub(:i2)

        base1 = Specification.new
        base1.stub(:each_interface).and_yield(interface1)

        base2 = Specification.new
        base2.stub(:each_interface).and_yield(interface2)

        spec = Specification.new([base1, base2])

        expect(spec.interfaces).to eq [interface1, interface2]
      end

      it "avoids duplications" do
        interface = stub(:i)

        base1 = Specification.new
        base1.stub(:each_interface).and_yield(interface)

        base2 = Specification.new
        base2.stub(:each_interface).and_yield(interface)

        spec = Specification.new([base1, base2])

        expect(spec.interfaces).to eq [interface]
      end

      it "accumulates interfaces from bases' bases" do
        interface1 = stub(:i1)
        interface2 = stub(:i2)

        base1 = Specification.new
        base1.stub(:each_interface).and_yield(interface1)

        base2 = Specification.new
        base2.stub(:each_interface).and_yield(interface2)

        base3 = Specification.new([base2])
        spec = Specification.new([base1, base3])

        expect(spec.interfaces).to eq [interface1, interface2]
      end
    end
  end
end
