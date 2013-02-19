require 'spec_helper'
require 'accord'

describe "Subscriptions" do
  let(:registry) { Accord::SubscriptionRegistry.new }
  let(:ip1) { Accord::InterfaceClass.new(:ip1, [Accord::Interface]) }
  let(:ir1) { Accord::InterfaceClass.new(:ir1, [Accord::Interface]) }

  context "single" do
    context "registrations for same interface" do
      before do
        registry.subscribe([ir1], ip1) { 'sub1' }
        registry.subscribe([ir1], ip1) { 'sub2' }
      end

      specify "are returned by order of definition" do
        items = registry.lookup([ir1], ip1).map do |sub|
          sub.call
        end
        expect(items).to eq ['sub1', 'sub2']
      end

      context "and also for all interfaces" do
        before do
          registry.subscribe([nil], ip1) { 'general' }
        end

        specify "are returned first" do
          items = registry.lookup([ir1], ip1).map do |sub|
            sub.call
          end
          expect(items).to eq ['general', 'sub1', 'sub2']
        end
      end
    end
  end

  context "multi" do
    let(:ir2) { Accord::InterfaceClass.new(:ir2, [Accord::Interface]) }

    before do
      registry.subscribe([ir1, ir2], ip1) { 'sub1' }
      registry.subscribe([ir1, ir2], ip1) { 'sub2' }
    end

    specify "are returned by order of definition" do
      items = registry.lookup([ir1, ir2], ip1).map do |sub|
        sub.call
      end
      expect(items).to eq ['sub1', 'sub2']
    end

    context "with a registration for all interfaces as first discriminator" do
      before do
        registry.subscribe([nil, ir2], ip1) { 'general' }
      end

      it "returns that registration first" do
        items = registry.lookup([ir1, ir2], ip1).map do |sub|
          sub.call
        end
        expect(items).to eq ['general', 'sub1', 'sub2']
      end
    end
  end

  context "null" do
    before do
      registry.subscribe([], ip1) { 'sub1' }
      registry.subscribe([], ip1) { 'sub2' }
    end

    specify "are returned by order of definition" do
      items = registry.lookup([], ip1).map do |sub|
        sub.call
      end
      expect(items).to eq ['sub1', 'sub2']
    end
  end

  describe "unregistration" do
    let(:subscriber1) { Proc.new { 'sub1' } }
    let(:subscriber2) { Proc.new { 'sub2' } }

    before do
      registry.subscribe([ir1], ip1, &subscriber1)
      registry.subscribe([ir1], ip1, &subscriber2)
    end

    subject { registry.lookup([ir1], ip1).map { |sub| sub.call } }

    context "when a specific subscriber is specified" do
      before do
        registry.unsubscribe([ir1], ip1, subscriber1)
      end

      it "unregisters only it" do
        expect(subject).to eq ['sub2']
      end
    end

    context "when no subscriber is specified" do
      before do
        registry.unsubscribe([ir1], ip1)
      end

      it "unregisters all" do
        expect(subject).to be_empty
      end
    end
  end

  describe "Subscription adapters" do
    let(:cls) { Class.new { Accord::Declarations.implements(self, IR1) } }
    let(:obj) { cls.new }

    before { stub_const('IR1', ir1) }

    context "single" do
      let(:calls) { [] }
      let(:s1)    { Proc.new { |o| calls << ['sub1', o]; ['sub1', o] } }
      let(:s2)    { Proc.new { |o| calls << ['sub2', o]; ['sub2', o] } }

      before do
        registry.subscribe([ir1], ip1, &s1)
        registry.subscribe([ir1], ip1, &s2)
      end

      specify "are get in the order they are subscribed" do
        items = registry.get([obj], ip1)
        expect(items).to eq [['sub1', obj], ['sub2', obj]]
      end

      specify "are called in the order they are subscribed" do
        registry.call([obj], ip1)
        expect(calls).to eq [['sub1', obj], ['sub2', obj]]
      end

      context "when a nil is returned by the subscriber" do
        before do
          registry.subscribe([ir1], ip1) { nil }
        end

        specify "#get doesn't return it" do
          items = registry.get([obj], ip1)
          expect(items).to eq [['sub1', obj], ['sub2', obj]]
        end
      end
    end

    context "multiple" do
      let(:ir2)  { Accord::InterfaceClass.new(:ir2, [Accord::Interface]) }
      let(:cls2) { Class.new { Accord::Declarations.implements(self, IR2) } }
      let(:obj2) { cls2.new }

      let(:calls) { [] }
      let(:s1)    { Proc.new { |r1, r2| calls << [1, r1, r2]; [1, r1, r2] } }
      let(:s2)    { Proc.new { |r1, r2| calls << [2, r1, r2]; [2, r1, r2] } }

      before do
        stub_const('IR2', ir2)
        registry.subscribe([ir1, ir2], ip1, &s1)
        registry.subscribe([ir1, ir2], ip1, &s2)
      end

      specify "are get in the order they are subscribed" do
        items = registry.get([obj, obj2], ip1)
        expect(items).to eq [[1, obj, obj2], [2, obj, obj2]]
      end

      specify "are called in the order they are subscribed" do
        registry.call([obj, obj2], ip1)
        expect(calls).to eq [[1, obj, obj2], [2, obj, obj2]]
      end

      context "when a nil is returned by the subscriber" do
        before do
          registry.subscribe([ir1, ir2], ip1) { nil }
        end

        specify "#get doesn't return it" do
          items = registry.get([obj, obj2], ip1)
          expect(items).to eq [[1, obj, obj2], [2, obj, obj2]]
        end
      end
    end

    context "null" do
      let(:calls) { [] }

      before do
        registry.subscribe([], ip1) { |*args| calls << [1, args]; 1 }
        registry.subscribe([], ip1) { |*args| calls << [2, args]; 2 }
      end

      specify "are get in the order they are subscribed" do
        items = registry.get([], ip1)
        expect(items).to eq [1, 2]
      end

      specify "are called in the order they are subscribed" do
        registry.call([], ip1)
        expect(calls).to eq [[1, []], [2, []]]
      end

      context "when a nil is returned by the subscriber" do
        before do
          registry.subscribe([], ip1) { nil }
        end

        specify "#get doesn't return it" do
          items = registry.get([], ip1)
          expect(items).to eq [1, 2]
        end
      end
    end
  end

  describe "Handlers" do
    let(:arguments) { [] }
    let(:obj)       { Object.new }

    before do
      registry.subscribe([ir1], nil) { |*args| arguments.concat(args) }
    end

    context "when required objects are satisfied" do
      before do
        Accord::Declarations.also_provides(obj, ir1)
      end

      specify "are called in the order they are defined" do
        registry.call([obj], nil)
        expect(arguments).to eq [obj]
      end
    end

    context "when required objects are not satisfied" do
      specify "are not called" do
        registry.call([obj], nil)
        expect(arguments).to be_empty
      end
    end
  end
end
