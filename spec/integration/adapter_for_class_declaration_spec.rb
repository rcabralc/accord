require 'spec_helper'
require 'accord'

describe "Adapter for class declaration" do
  let(:ip1)      { Accord::InterfaceClass.new(:ip1, [Accord::Interface]) }
  let(:registry) { Accord::AdapterRegistry.new }

  context "given a class claiming to implement an interface" do
    let(:cls) { Class.new }
    before { Accord::Declarations.implements(cls, ip1) }

    context "and a registration using the class declaration" do
      let(:declaration) { Accord::Declarations.implemented_by(cls) }

      before { registry.register([declaration], ip1, '') { 'value' } }

      it "returns that when the claimed interface is used for lookup" do
        expect(registry.lookup([declaration], ip1).call).to eq 'value'
      end
    end
  end
end
