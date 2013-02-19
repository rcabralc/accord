require 'spec_helper'
require 'accord/interface'

module Accord
  describe InterfaceClass do
    before { Accord.clear_adapter_hooks }

    specify "interfaces are just a kind of specification" do
      expect(InterfaceClass.new(:I)).to be_a(Specification)
    end

    it "returns self as its single interface" do
      interface = InterfaceClass.new(:I)
      expect(interface.interfaces).to eq [interface]
    end

    it "returns ancestor specs in #ancestors" do
      spec = Specification.new
      interface = InterfaceClass.new(:I, [spec])

      expect(interface.ancestors).to eq [interface, spec]
    end

    it "returns only ancestor interfaces in #iro" do
      spec = Specification.new
      interface = InterfaceClass.new(:I, [spec])

      expect(interface.iro).to eq [interface]
    end

    describe "#provided_by?" do
      let(:object)    { stub }
      let(:interface) { InterfaceClass.new(:I) }

      let(:provided_by_declaration) { stub(:extends? => false) }
      let(:declarations_module)     { stub }

      before do
        stub_const('Accord::Declarations', declarations_module)
        declarations_module.stub(:provided_by).with(object).
          and_return(provided_by_declaration)
      end

      it "returns false if the object is not told to provide the interface" do
        expect(interface).to_not be_provided_by(object)
      end

      it "returns true if the object is told to provide the interface" do
        provided_by_declaration.stub(:extends?).with(interface).
          and_return(true)
        expect(interface).to be_provided_by(object)
      end
    end

    describe "#implemented_by?" do
      let(:factory)   { stub }
      let(:interface) { InterfaceClass.new(:I) }

      let(:implemented_by_declaration) { stub(:extends? => false) }
      let(:declarations_module)        { stub }

      before do
        stub_const('Accord::Declarations', declarations_module)
        declarations_module.stub(:implemented_by).with(factory).
          and_return(implemented_by_declaration)
      end

      it "returns false if the factory is not told to implement the interface" do
        expect(interface).to_not be_implemented_by(factory)
      end

      it "returns true if the factory is told to implement the interface" do
        implemented_by_declaration.stub(:extends?).with(interface).
          and_return(true)
        expect(interface).to be_implemented_by(factory)
      end
    end

    describe "#adapt" do
      let(:interface) { InterfaceClass.new(:I) }
      let(:object)    { stub }
      let(:adapter)   { stub }
      let(:hook_miss) { Proc.new { |iface, *obs| nil } }
      let(:hook_hit)  { Proc.new { |iface, *obs| adapter } }

      it "returns nil if no hook is installed" do
        expect(interface.adapt(object)).to be_nil
      end

      it "returns nil if all hooks fail" do
        Accord.install_adapter_hook(hook_miss)
        Accord.install_adapter_hook(hook_miss)
        Accord.install_adapter_hook(hook_miss)

        expect(interface.adapt(object)).to be_nil
      end

      it "returns the result of the first hook which succeeds" do
        hook_hit2 = Proc.new { |iface, *obs| 'other adapter' }

        Accord.install_adapter_hook(hook_miss)
        Accord.install_adapter_hook(hook_hit)
        Accord.install_adapter_hook(hook_miss)
        Accord.install_adapter_hook(hook_hit2)
        Accord.install_adapter_hook(hook_miss)

        expect(interface.adapt(object)).to be adapter
      end

      context "when the hook actually cares about what is being adapted" do
        let(:hook_hit) { stub }

        before do
          hook_hit.stub(:call).with(interface, object, object).
            and_return(adapter)
          Accord.install_adapter_hook(hook_hit)
        end

        subject { interface.adapt(object, object) }
        it      { should be adapter }
      end
    end

    describe "#adapt!" do
      let(:interface) { InterfaceClass.new(:I) }
      let(:object)    { stub }
      let(:adapter)   { stub }
      let(:hook_miss) { Proc.new { |iface, *obs| nil } }
      let(:hook_hit)  { Proc.new { |iface, *obs| adapter } }

      it "raises TypeError if there's no hook installed" do
        expect { interface.adapt!(object) }.to raise_error(TypeError)
      end

      it "raises TypeError if no hook provided a suitable adapter" do
        Accord.install_adapter_hook(Proc.new { |iface, *obs| nil })

        expect { interface.adapt!(object) }.to raise_error(TypeError)
      end

      it "returns the adapter if one hook succeeded" do
        Accord.install_adapter_hook(Proc.new { |iface, *obs| adapter })
        expect(interface.adapt!(object)).to be adapter
      end
    end
  end
end
