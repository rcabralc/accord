require 'spec_helper'
require 'accord/declarations'
require 'accord/interface'

module Accord
  describe Declarations do
    let(:i1)  { InterfaceClass.new(:I1, [Interface]) }
    let(:cls) { Class.new }

    describe "class declarations" do
      let(:mod) { Module.new }

      specify "are empty by default" do
        expect(Declarations.implemented_by(cls).interfaces).to be_empty
      end

      describe "implemented" do
        it "can be modified to implement a specific interface" do
          Declarations.implements(cls, i1)
          expect(Declarations.implemented_by(cls)).to be_extend(i1)
        end

        it "can inherit interfaces from superclasses" do
          Declarations.implements(cls, i1)
          subclass = Class.new(cls)
          expect(Declarations.implemented_by(subclass)).to be_extend(i1)
        end

        it "can inherit interfaces from included modules" do
          Declarations.implements(mod, i1)
          cls.send(:include, mod)
          expect(Declarations.implemented_by(cls)).to be_extend(i1)
        end

        it "makes the class to implement the interface" do
          Declarations.implements(cls, i1)
          expect(i1).to be_implemented_by(cls)
        end

        it "makes instance to provide the interface" do
          Declarations.implements(cls, i1)
          expect(i1).to be_provided_by(cls.new)
        end
      end

      describe "implemented only" do
        let(:i2) { InterfaceClass.new(:i2, [Interface]) }

        before do
          Declarations.implements(cls, i1)
        end

        it "can be modified to implement a specific interface only" do
          Declarations.implements_only(cls, i2)
          expect(Declarations.implemented_by(cls)).to be_extend(i2)
          expect(Declarations.implemented_by(cls)).to_not be_extend(i1)
        end
      end
    end

    describe "proc declarations" do
      let(:prc) { Proc.new {} }

      specify "are empty by default" do
        expect(Declarations.implemented_by(prc).interfaces).to be_empty
      end

      describe "implemented" do
        it "can be modified to implement a specific interface" do
          Declarations.implements(prc, i1)
          expect(Declarations.implemented_by(prc)).to be_extend(i1)
        end
      end

      describe "implemented only" do
        let(:i2) { InterfaceClass.new(:i2, [Interface]) }

        before do
          Declarations.implements(prc, i1)
        end

        it "can be modified to implement a specific interface only" do
          Declarations.implements_only(prc, i2)
          expect(Declarations.implemented_by(prc)).to be_extend(i2)
          expect(Declarations.implemented_by(prc)).to_not be_extend(i1)
        end
      end
    end

    describe "object declarations" do
      let(:i2)  { InterfaceClass.new(:i2, [Interface]) }
      let(:obj) { cls.new }

      specify "are empty by default" do
        expect(Declarations.provided_by(obj).interfaces).to be_empty
      end

      describe ".also_provides" do
        it "makes the object to provide an interface" do
          Declarations.also_provides(obj, i1)
          expect(i1).to be_provided_by(obj)
        end

        it "adds interfaces to the object" do
          Declarations.also_provides(obj, i1)
          Declarations.also_provides(obj, i2)
          expect(i2).to be_provided_by(obj)
        end
      end

      describe ".directly_provides" do
        it "makes an object to provide only the given interfaces" do
          Declarations.also_provides(obj, i2)
          Declarations.directly_provides(obj, i1)
          expect(i1).to be_provided_by(obj)
          expect(i2).to_not be_provided_by(obj)
        end

        it "doesn't affect interfaces provided from the object's class" do
          Declarations.implements(cls, i1)
          Declarations.directly_provides(obj, i2)
          expect(i1).to be_provided_by(obj)
          expect(i2).to be_provided_by(obj)
        end
      end

      describe ".no_longer_provides" do
        it "makes the object to not provide a specific interface" do
          Declarations.also_provides(obj, i1)
          Declarations.also_provides(obj, i2)
          Declarations.no_longer_provides(obj, i1)
          expect(i1).to_not be_provided_by(obj)
          expect(i2).to be_provided_by(obj)
        end

        it "doesn't affect interfaces provided from the object's class" do
          Declarations.implements(cls, i1)
          Declarations.no_longer_provides(obj, i1)
          expect(i1).to be_provided_by(obj)
        end
      end
    end
  end
end
