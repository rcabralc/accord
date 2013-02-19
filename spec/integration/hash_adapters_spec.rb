require 'spec_helper'
require 'accord'

describe "Hash adapters" do
  let(:ip)       { Accord::InterfaceClass.new(:ip, [Accord::Interface]) }
  let(:registry) { Accord::AdapterRegistry.new }

  context "given a hash" do
    let(:hash) { Hash.new }

    context "and a registration for it using no required interfaces" do
      before { registry.register([], ip, '') { hash } }

      it "returns that when the lookup is made without required interfaces "\
         "for the right provided interface" do
        expect(registry.lookup([], ip).call).to be hash
      end
    end
  end
end
