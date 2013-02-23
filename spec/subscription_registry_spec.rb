require 'spec_helper'
require 'accord/subscription_registry'

module Accord
  describe SubscriptionRegistry do
    subject(:registry) { SubscriptionRegistry.new }

    let(:subscriber)       { Proc.new {} }
    let(:other_subscriber) { Proc.new {} }

    let(:i1) { stub_interface }
    let(:i2) { stub_interface }

    def stub_interface(*bases)
      stub.tap do |interface|
        interface.stub(
          :iro => [interface],
          :ancestors => [interface]
        )
        interface.stub(:extends?).and_return(false)
        interface.stub(:extends?).with(interface).and_return(true)
        bases.each do |base|
          interface.iro << base
          interface.ancestors << base
          interface.stub(:extends?).with(base).and_return(true)
        end
      end
    end

    describe "#all" do
      it "returns no adapter when registry is empty" do
        expect(subject.all).to be_empty
      end

      context "subscribed most simple single subscriber" do
        it "returns that if no arguments are passed" do
          subject.subscribe([Interface], Interface, &subscriber)
          expect(subject.all).to eq [subscriber]
        end
      end

      it "hits right subscriber if matches" do
        subject.subscribe([i1], nil, &subscriber)
        expect(
          subject.all(required: [i1], provided: nil)
        ).to eq [subscriber]
      end

      it "miss subscriber if none matches" do
        subject.subscribe([i1], nil, &subscriber)
        expect(
          subject.all(required: [i2], provided: nil)
        ).to be_empty
      end
    end

    describe "#subscribe" do
      it "complains if subscription happens without block" do
        expect {
          subject.subscribe([Interface], Interface, '')
        }.to raise_error(ArgumentError)
      end

      it "allows subscribing a null subscriber" do
        subject.subscribe([], i1, &subscriber)
        expect(subject.all(required: [], provided: i1)).to eq [subscriber]
      end

      it "subscribes multiple subscribers" do
        subject.subscribe([nil], nil, &subscriber)
        subject.subscribe([nil], nil, &other_subscriber)
        expect(
          subject.all(required: [Interface], provided: Interface)
        ).to eq [subscriber, other_subscriber]
      end

      context "when using [nil] and nil for required and provided" do
        it "defaults to most simple single subscriber" do
          subject.subscribe([nil], nil, &subscriber)
          expect(
            subject.all(required: [Interface], provided: Interface)
          ).to eq [subscriber]
        end
      end

      context "when using nil and nil for required and provided" do
        it "defaults to most simple single subscriber" do
          subject.subscribe(nil, nil, &subscriber)
          expect(
            subject.all(required: [Interface], provided: Interface)
          ).to eq [subscriber]
        end
      end
    end

    describe "#lookup" do
      it "returns no subscriber when registry is empty" do
        expect(subject.lookup([], nil)).to be_empty
      end

      context "registered most simple single subscriber" do
        before do
          subject.subscribe([Interface], Interface, &subscriber)
        end

        it "returns that if required is nil and provided is nil" do
          expect(subject.lookup(nil, nil)).to eq [subscriber]
        end

        it "returns that if required is [nil] and provided is nil" do
          expect(subject.lookup([nil], nil)).to eq [subscriber]
        end
      end

      it "hits right subscriber if matches exactly" do
        subject.subscribe([i1], nil, &subscriber)
        expect(subject.lookup([i1], nil)).to eq [subscriber]
      end

      it "hits right subscriber if required extends some registered" do
        i12 = stub_interface(i1)
        subject.subscribe([i1], nil, &subscriber)
        expect(subject.lookup([i12], nil)).to eq [subscriber]
      end

      it "miss subscriber if none matches" do
        subject.subscribe([i1], nil, &subscriber)
        expect(subject.lookup([i2], nil)).to be_empty
      end
    end

    describe "#unsubscribe" do
      it "doesn't complain when unsubscribing empty registry" do
        expect { subject.unsubscribe([nil], nil) }.to_not raise_error
      end

      it "keeps subscribed if required doesn't match on unsubscription" do
        subject.subscribe([i1], nil, &subscriber)
        subject.unsubscribe([i2], nil)
        expect(
          subject.all(required: [i1], provided: nil)
        ).to eq [subscriber]
      end

      it "keeps subscribed if provided doesn't match on unsubscription" do
        subject.subscribe([nil], i1, &subscriber)
        subject.unsubscribe([nil], i2)
        expect(
          subject.all(required: [nil], provided: i1)
        ).to eq [subscriber]
      end

      it "keeps subscribed if value is passed but doesn't match on "\
         "unsubscription" do
        subject.subscribe([i1], nil, &subscriber)
        subject.unsubscribe([i1], nil, stub)
        expect(
          subject.all(required: [i1], provided: nil)
        ).to eq [subscriber]
      end

      it "unsubscribes only subscribers matching the value passed" do
        subject.subscribe([i1], nil, &subscriber)
        subject.subscribe([i1], nil, &other_subscriber)
        subject.unsubscribe([i1], nil, subscriber)
        expect(
          subject.all(required: [i1], provided: nil)
        ).to eq [other_subscriber]
      end

      it "unsubscribes if value not passed and everything else matches "\
         "previous subscription" do
        subject.subscribe([i1], nil, &subscriber)
        subject.unsubscribe([i1], nil)
        expect(
          subject.all(required: [i1], provided: nil)
        ).to be_empty
      end

      it "unsubscribes all if value not passed" do
        subject.subscribe([i1], nil, &subscriber)
        subject.subscribe([i1], nil, &other_subscriber)
        subject.unsubscribe([i1], nil)
        expect(
          subject.all(required: [i1], provided: nil, name: '')
        ).to be_empty
      end

      context "when using [nil] and nil for required and provided" do
        it "defaults to most simple single adapter" do
          subject.subscribe([Interface], Interface, &subscriber)
          subject.unsubscribe([nil], nil)
          expect(subject.all).to be_empty
        end
      end

      context "when using nil and nil for required and provided" do
        it "defaults to most simple single adapter" do
          subject.subscribe([Interface], Interface, &subscriber)
          subject.unsubscribe(nil, nil)
          expect(subject.all).to be_empty
        end
      end
    end
  end
end
