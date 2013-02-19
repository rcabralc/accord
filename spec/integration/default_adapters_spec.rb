require 'spec_helper'
require 'accord'

describe "Default adapters" do
  let(:registry) { Accord::AdapterRegistry.new }
  let(:ip1) { Accord::InterfaceClass.new(:ip1, [Accord::Interface]) }
  let(:ir1) { Accord::InterfaceClass.new(:ir1, [Accord::Interface]) }

  before do
    stub_const('IP1', ip1)
    stub_const('IR1', ir1)
  end

  context "single" do
    before do
      registry.register([nil], IP1, '') { 1 }
    end

    context "for interfaces we don't have specific adapters for" do
      let(:iq) { Accord::InterfaceClass.new(:iq, [Accord::Interface]) }

      it "finds the default adapter" do
        expect(registry.lookup([iq], IP1, '').call).to eq 1
      end
    end

    context "when a specific adapter is also registered" do
      let(:ir1) { Accord::InterfaceClass.new(:ir1, [Accord::Interface]) }

      before do
        registry.register([ir1], IP1, '') { 2 }
      end

      it "overrides the default" do
        expect(registry.lookup([ir1], IP1, '').call).to eq 2
      end
    end
  end

  context "multi" do
    before do
      registry.register([nil, IR1], IP1, '') { 1 }
    end

    context "for interfaces we don't have specific adapters for" do
      let(:iq) { Accord::InterfaceClass.new(:iq, [Accord::Interface]) }

      it "finds the default adapter" do
        expect(registry.lookup([iq, IR1], IP1, '').call).to eq 1
      end
    end

    context "when a specific adapter is also registered" do
      let(:ir2) { Accord::InterfaceClass.new(:ir2, [Accord::Interface]) }

      before do
        registry.register([ir2, IR1], IP1, '') { 2 }
      end

      it "overrides the default" do
        expect(registry.lookup([ir2, IR1], IP1, '').call).to eq 2
      end
    end
  end

  context "null" do
    let(:ip2) { Accord::InterfaceClass.new(:ip2, [ip1]) }

    before do
      registry.register([], ip2, '') { 'null adapter' }
    end

    it "also can adapt no specification" do
      expect(registry.lookup([], ip2, '').call).to eq 'null adapter'
    end

    it "will take into consideration any extending interface" do
      expect(registry.lookup([], IP1, '').call).to eq 'null adapter'
    end
  end
end
