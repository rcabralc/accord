require 'spec_helper'
require 'accord'

describe "Adaptation" do
  let(:registry) { Accord::AdapterRegistry.new }
  let(:ip1) { Accord::InterfaceClass.new(:ip1, [Accord::Interface]) }

  let(:yclass) { Class.new do
    Accord::Declarations.implements(self, IP1)
    attr_reader :context
    def initialize(context)
      @context = context
    end
  end }

  before do
    stub_const('IP1', ip1)
  end

  describe "getting an adapter" do
    let(:ir)     { Accord::InterfaceClass.new(:ir, [Accord::Interface]) }
    let(:xclass) { Class.new { Accord::Declarations.implements(self, IR) } }
    let(:x)      { xclass.new }

    before do
      stub_const('IR', ir)
    end

    context "unamed" do
      subject { registry.get([x], IP1) }

      before do
        registry.register([IR], IP1, '') { |o| yclass.new(o) }
      end

      it { should be_a(yclass) }
      its(:context) { should be x }
    end

    context "named" do
      let(:y2class) { Class.new(yclass) }
      subject { registry.get([x], IP1, 'bob') }

      before do
        registry.register([IR], IP1, 'bob') { |o| y2class.new(o) }
      end

      it { should be_a(y2class) }
      its(:context) { should be x }
    end

    describe "factory with embedded condition" do
      let(:factory) { Proc.new { |o| o.name == 'object' ? 'adapter' : nil } }
      let(:oclass) { Class.new do
        Accord::Declarations.implements(self, IR)
        attr_writer :name
        def name
          @name ||= 'object'
        end
      end }
      let(:obj) { oclass.new }

      before do
        registry.register([IR], IP1, 'conditional', &factory)
      end

      context "when the adapter satisfies the condition" do
        subject { registry.get([obj], IP1, 'conditional') }
        it { should eq 'adapter' }
      end

      context "when the adapter doesn't satisfy the condition" do
        subject { registry.get([obj], IP1, 'conditional') }
        before { obj.name = 'other' }
        it { should be_nil }

        context "when a default value is provided" do
          subject do
            registry.get([obj], IP1, 'conditional', default: 'default')
          end
          it { should eq 'default' }
        end
      end
    end
  end
end
