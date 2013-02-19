require 'spec_helper'
require 'accord'

describe "Named adapters" do
  let(:registry) { Accord::AdapterRegistry.new }

  context "single" do
    let(:ip1) { Accord::InterfaceClass.new(:ip1, [Accord::Interface]) }
    let(:ir1) { Accord::InterfaceClass.new(:ir1, [Accord::Interface]) }

    before do
      registry.register([ir1], ip1, '') { 1 }
      registry.register([ir1], ip1, 'bob') { 2 }
    end

    subject do
      registry.lookup_all([ir1], ip1).map { |name, fac| [name, fac.call] }
    end

    it { should eq [['', 1], ['bob', 2]] }
  end

  context "multi" do
    let(:ip1) { Accord::InterfaceClass.new(:ip1, [Accord::Interface]) }
    let(:ir1) { Accord::InterfaceClass.new(:ir1, [Accord::Interface]) }
    let(:ir2) { Accord::InterfaceClass.new(:ir2, [Accord::Interface]) }

    before do
      registry.register([ir1, ir2], ip1, '') { 1 }
      registry.register([ir1, ir2], ip1, 'bob') { 2 }
    end

    subject do
      registry.lookup_all([ir1, ir2], ip1).map { |name, fac| [name, fac.call] }
    end

    it { should eq [['', 1], ['bob', 2]] }
  end

  context "null" do
    let(:ip1) { Accord::InterfaceClass.new(:ip1, [Accord::Interface]) }

    before do
      registry.register([], ip1, '') { 1 }
      registry.register([], ip1, 'bob') { 2 }
    end

    subject do
      registry.lookup_all([], ip1).map { |name, fac| [name, fac.call] }
    end

    it { should eq [['', 1], ['bob', 2]] }
  end
end
