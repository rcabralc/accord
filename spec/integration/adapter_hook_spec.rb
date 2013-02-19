require 'spec_helper'
require 'accord'

module Accord
  describe "Adapter hook" do
    before do
      Accord.install_default_adapter_hook
    end

    after do
      Accord.clear_adapter_hooks
      Accord.clear_default_adapter_hook
    end

    let(:itarget)  { InterfaceClass.new(:itarget, [Interface]) }
    let(:registry) { Accord.default_adapter_registry }

    it "makes interfaces adapt using the default adapter hook" do
      ir = InterfaceClass.new(:ir, [Interface])
      registry.register([ir], itarget) { 'adapted' }

      obj = Object.new
      Accord::Declarations.also_provides(obj, ir)

      expect(itarget.adapt(obj)).to eq 'adapted'
    end

    it "also enables multi adaptation from interfaces" do
      ir1 = InterfaceClass.new(:ir1, [Interface])
      ir2 = InterfaceClass.new(:ir2, [Interface])
      registry.register([ir1, ir2], itarget) { 'adapted' }

      obj1 = Object.new
      obj2 = Object.new
      Declarations.also_provides(obj1, ir1)
      Declarations.also_provides(obj2, ir2)

      expect(itarget.adapt(obj1, obj2)).to eq 'adapted'
    end
  end
end
