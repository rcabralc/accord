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
      let(:most_basic) { Specification.new }
      let(:base1)      { Specification.new([most_basic]) }
      let(:base2)      { Specification.new([base1, most_basic]) }
      let(:base3)      { Specification.new([most_basic]) }
      let(:base4)      { Specification.new([base2, base3]) }
      let(:spec)       { Specification.new([base3, base2, base4]) }

      let(:expected_base_order) {[
        spec,
        base3,
        most_basic,
        base2,
        base1,
        base4,
      ]}

      it "orders the ancestry just like ruby's module resolution order" do
        expect(spec.ancestors).to eq expected_base_order
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

      it "cannot modify bases directly" do
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
