require 'spec_helper'
require 'accord/interface_body'

module Accord
  describe InterfaceBody do
    let(:interface) { stub }
    let(:bases) { [] }
    let(:methods) { stub }
    let(:invariants) { stub }

    subject { InterfaceBody.new(interface, bases, methods, invariants) }

    describe "#extends" do
      let(:base1) { stub }
      let(:base2) { stub }

      it "adds up interfaces" do
        subject.extends(base1)
        expect(bases).to include(base1)
      end

      it "doesn't add a already added base" do
        subject.extends(base1)
        subject.extends(base1)
        expect(bases.size).to eq 1
      end

      it "prepends the added bases" do
        subject.extends(base1)
        subject.extends(base2)

        expect(bases.shift).to be base2
        expect(bases.shift).to be base1
      end
    end

    describe "#responds_to" do
      it "adds up methods" do
        methods.should_receive(:add).with(:method)
        subject.responds_to(:method)
      end

      it "adds the method passing the params, when they are given" do
        methods.should_receive(:add).with(:method, params: 'params')
        subject.responds_to(:method, params: 'params')
      end

      it "forwards the block, if given" do
        block = Proc.new { }
        methods.should_receive(:add).with(:method, &block)
        subject.responds_to(:method, &block)
      end
    end

    describe "#invariant" do
      it "adds up invariants" do
        block = Proc.new { }
        invariants.should_receive(:add).with(:invariant, &block)
        subject.invariant(:invariant, &block)
      end
    end

    describe "#interface" do
      it "exposes the interface object" do
        expect(subject.interface).to be interface
      end
    end

    describe "#tags" do
      let(:tags) { stub }

      it "expose interface tags" do
        interface.stub(:tags).and_return(tags)
        expect(subject.tags).to be tags
      end
    end

    describe ".run" do
      subject { InterfaceBody }
      let(:root_interface) { stub }

      before do
        stub_const('Accord::Interface', root_interface)
        interface.stub(:bases=)
        interface.stub(:methods)
        interface.stub(:invariants)
      end

      it "adds the root interface if bases is left empty" do
        interface.should_receive(:bases=).with([root_interface])
        subject.run(interface) { }
      end

      it "doesn't add root interface if bases has at least one interface" do
        stub_const('Accord::TestInterface', stub)
        interface.should_receive(:bases=).with([Accord::TestInterface])
        subject.run(interface) { extends Accord::TestInterface }
      end

      it "runs the block in an instance" do
        instance = nil
        subject.run(interface) { instance = self }
        expect(instance).to be_a InterfaceBody
      end
    end
  end
end
