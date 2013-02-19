require 'spec_helper'
require 'accord'

describe "Single adapters" do
  let(:registry) { Accord::AdapterRegistry.new }
  let(:ir1) { Accord::InterfaceClass.new(:ir1, [Accord::Interface]) }
  let(:ir2) { Accord::InterfaceClass.new(:ir2, [ir1]) }
  let(:ip1) { Accord::InterfaceClass.new(:ip1, [Accord::Interface]) }
  let(:ip2) { Accord::InterfaceClass.new(:ip2, [ip1]) }
  let(:ip3) { Accord::InterfaceClass.new(:ip3, [ip2]) }

  before do
    registry.register([ir1], ip2, '') { 12 }
  end

  specify "exact lookup" do
    expect(registry.lookup([ir1], ip2, '').call).to eq 12
  end

  specify "lookup using an extension of a previously registered adapter" do
    expect(registry.lookup([ir2], ip2, '').call).to eq 12
  end

  specify "lookup by class implementation" do
    cls = Class.new
    Accord::Declarations.implements(cls, ir2)
    expect(registry.lookup([ir2], ip2, '').call).to eq 12
  end

  specify "lookup for interface whose registration's provided extends" do
    expect(registry.lookup([ir2], ip1, '').call).to eq 12
  end

  specify "lookup for spec not extending registered one" do
    expect(registry.lookup([Accord::Interface], ip1, '')).to be_nil
  end

  specify "lookup for spec not extending registered one, with default" do
    expect(registry.lookup([Accord::Interface], ip1, '',
                           default: lambda { 42 }).call).to eq 42
  end

  specify "lookup for interface not provided by any registration" do
    expect(registry.lookup([ir1], ip3, '')).to be_nil
  end

  specify "lookup by name" do
    expect(registry.lookup([ir1], ip1, 'bob')).to be_nil
    registry.register([ir1], ip2, 'bob') { "Bob's 12" }
    expect(registry.lookup([ir1], ip1, 'bob').call).to eq "Bob's 12"
  end

  specify "lookup omitting name" do
    expect(registry.lookup([ir1], ip1).call).to eq 12
  end

  specify "lookup for adapter providing more appropriated spec" do
    registry.register([ir1], ip1, '') { 11 }
    expect(registry.lookup([ir1], ip1, '').call).to eq 11
  end

  specify "lookup for more specific adapter" do
    registry.register([ir2], ip2, '') { 21 }
    expect(registry.lookup([ir2], ip1, '').call).to eq 21
  end

  describe "detecting exactly matches" do
    specify "getting less specific" do
      registry.register([ir1], ip1, '') { 11 }
      expect(registry.detect(required: [ir1], provided: ip1).call).to eq 11
    end

    specify "getting more specific" do
      expect(registry.detect(required: [ir1], provided: ip2).call).to eq 12
    end

    specify "getting more specific with name" do
      registry.register([ir1], ip2, 'bob') { "Bob's 12" }
      expect(
        registry.detect(required: [ir1], provided: ip2, name: 'bob').call
      ).to eq "Bob's 12"
    end

    specify "using more specific required interface" do
      registry.register([ir2], ip2, '') { 21 }
      expect(registry.detect(required: [ir2], provided: ip2).call).to eq 21
    end

    specify "missing by trying to get a unregistered adapter" do
      expect(registry.detect(required: [ir2], provided: ip2)).to be_nil
    end
  end
end
