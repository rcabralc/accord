require 'spec_helper'
require 'accord'

describe "Multi adapters" do
  let(:ip)  { Accord::InterfaceClass.new(:ip, [Accord::Interface]) }
  let(:ir1) { Accord::InterfaceClass.new(:ir1, [Accord::Interface]) }
  let(:ir2) { Accord::InterfaceClass.new(:ir2, [Accord::Interface]) }

  let(:registry) { Accord::AdapterRegistry.new }

  before do
    stub_const('IR1', ir1)
    stub_const('IR2', ir2)
  end

  context "given a factory requiring more than one parameter" do
    let(:factory) { Proc.new { |o1, o2| 'factory result' } }

    context "and a registered adapter for those discriminators" do
      before do
        registry.register([ir1, ir2], ip, '') { 'adapter' }
      end

      context "when a query is made for objects providing those "\
              "required interfaces" do
        let(:cls1) { Class.new { Accord::Declarations.implements(self, IR1) } }
        let(:cls2) { Class.new { Accord::Declarations.implements(self, IR2) } }

        let(:r1) { cls1.new }
        let(:r2) { cls2.new }

        subject { registry.get([r1, r2], ip, '') }

        it { should eq 'adapter' }
      end

      context "when a query is made for objects providing those "\
              "required interfaces with the wrong name" do
        let(:cls1) { Class.new { Accord::Declarations.implements(self, IR1) } }
        let(:cls2) { Class.new { Accord::Declarations.implements(self, IR2) } }

        let(:r1) { cls1.new }
        let(:r2) { cls2.new }

        subject { registry.get([r1, r2], ip, 'not unamed') }

        it { should be_nil }
      end
    end

    context "and a named registered adapter for those discriminators" do
      before do
        registry.register([ir1, ir2], ip, 'bob') { 'adapter' }
      end

      context "when a query is made for objects providing those "\
              "required interfaces with the right name" do
        let(:cls1) { Class.new { Accord::Declarations.implements(self, IR1) } }
        let(:cls2) { Class.new { Accord::Declarations.implements(self, IR2) } }

        let(:r1) { cls1.new }
        let(:r2) { cls2.new }

        subject { registry.get([r1, r2], ip, 'bob') }

        it { should eq 'adapter' }
      end

      context "when a query is made for objects providing those "\
              "required interfaces with the wrong name (unamed)" do
        let(:cls1) { Class.new { Accord::Declarations.implements(self, IR1) } }
        let(:cls2) { Class.new { Accord::Declarations.implements(self, IR2) } }

        let(:r1) { cls1.new }
        let(:r2) { cls2.new }

        subject { registry.get([r1, r2], ip, '') }

        it { should be_nil }
      end
    end
  end
end
