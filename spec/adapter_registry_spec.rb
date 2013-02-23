require 'spec_helper'
require 'accord/adapter_registry'

module Accord
  describe AdapterRegistry do
    subject { AdapterRegistry.new }

    let(:adapter_factory)       { Proc.new {} }
    let(:other_adapter_factory) { Proc.new {} }


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

    describe "#first" do
      it "returns no adapter when registry is empty" do
        expect(subject.first).to be_nil
      end

      context "registered most simple single adapter" do
        it "returns that if no arguments are passed" do
          subject.register([Interface], Interface, '', &adapter_factory)
          expect(subject.first).to be adapter_factory
        end
      end

      it "hits right adapter factory if matches" do
        subject.register([i1], nil, '', &adapter_factory)
        expect(
          subject.first(required: [i1], provided: nil, name: '')
        ).to be adapter_factory
      end

      it "miss adapter factory if none matches" do
        subject.register([i1], nil, '', &adapter_factory)
        expect(
          subject.first(required: [i2], provided: nil, name: '')
        ).to be_nil
      end
    end

    describe "#all" do
      it "returns no adapter when empty" do
        expect(subject.all).to be_empty
      end

      context "registered most simple single adapter" do
        before do
          subject.register([Interface], Interface, '', &adapter_factory)
        end

        it "returns that if no arguments are passed" do
          expect(subject.all).to eq [['', adapter_factory]]
        end
      end

      context "selection in registration for multiple names" do
        it "returns all registered adapters" do
          subject.register([nil], nil, &adapter_factory)
          subject.register([nil], nil, 'other name', &other_adapter_factory)
          expect(subject.all(required: [nil], provided: nil)).to eq [
            ['',           adapter_factory],
            ['other name', other_adapter_factory]
          ]
        end
      end
    end

    describe "#register" do
      it "complains if registration happens without block" do
        expect {
          subject.register([Interface], Interface, '')
        }.to raise_error(ArgumentError)
      end

      it "allows registering a null adapter" do
        subject.register([], i1, '', &adapter_factory)
        expect(
          subject.first(required: [], provided: i1, name:'')
        ).to be adapter_factory
      end

      context "when using [nil] and nil for required and provided" do
        it "defaults to most simple single adapter" do
          subject.register([nil], nil, '', &adapter_factory)
          expect(
            subject.first(required: [Interface], provided: Interface, name: '')
          ).to be adapter_factory
        end
      end

      context "when using nil and nil for required and provided" do
        it "defaults to most simple single adapter" do
          subject.register(nil, nil, '', &adapter_factory)
          expect(
            subject.first(required: [Interface], provided: Interface, name: '')
          ).to be adapter_factory
        end
      end

      context "registration without name" do
        it "defaults to empty name" do
          subject.register([nil], nil, &adapter_factory)
          expect(
            subject.first(required: [nil], provided: nil, name: '')
          ).to be adapter_factory
        end
      end
    end

    describe "#lookup" do
      it "returns no adapter when registry is empty" do
        expect(subject.lookup([], nil)).to be_nil
      end

      context "registered most simple single adapter" do
        before do
          subject.register([Interface], Interface,
                           '', &adapter_factory)
        end

        it "returns that if required is nil and provided is nil" do
          expect(subject.lookup(nil, nil)).to be adapter_factory
        end

        it "returns that if required is [nil] and provided is nil" do
          expect(subject.lookup([nil], nil)).to be adapter_factory
        end
      end

      it "hits right adapter factory if matches exactly" do
        subject.register([i1], nil, '', &adapter_factory)
        expect(
          subject.lookup([i1], nil, '')
        ).to be adapter_factory
      end

      it "defaults name to empty string" do
        subject.register([i1], nil, '', &adapter_factory)
        expect(subject.lookup([i1], nil)).to be adapter_factory
      end

      it "hits right adapter factory if required extends some registered" do
        i12 = stub_interface(i1)
        subject.register([i1], nil, '', &adapter_factory)
        expect(subject.lookup([i12], nil, '')).to be adapter_factory
      end

      it "miss adapter factory if none matches" do
        subject.register([i1], nil, '', &adapter_factory)
        expect(subject.lookup([i2], nil, '')).to be_nil
      end

      it "returns default value if missed" do
        subject.register([i1], nil, '', &adapter_factory)
        expect(subject.lookup([i2], nil, default: 'default')).to eq 'default'
      end
    end

    describe "#lookup_all" do
      it "returns no adapter when registry is empty" do
        expect(subject.lookup_all([], nil)).to be_empty
      end

      context "registered most simple single adapter" do
        before do
          subject.register([Interface], Interface, '', &adapter_factory)
        end

        it "returns that if required is nil and provided is nil" do
          expect(subject.lookup_all(nil, nil)).to eq({'' => adapter_factory})
        end

        it "returns that if required is [nil] and provided is nil" do
          expect(subject.lookup_all([nil], nil)).to eq({'' => adapter_factory})
        end
      end

      it "hits right adapter factory if matches" do
        subject.register([i1], nil, '', &adapter_factory)
        expect(subject.lookup_all([i1], nil)).to eq({'' => adapter_factory})
      end

      it "hits right adapter factory if required extends some registered" do
        i12 = stub_interface(i1)
        subject.register([i1], nil, '', &adapter_factory)
        expect(subject.lookup_all([i12], nil)).to eq({'' => adapter_factory})
      end

      it "hits right adapter factory if provided is extended by some registered" do
        i12 = stub_interface(i1)
        subject.register([nil], i12, '', &adapter_factory)
        expect(subject.lookup_all([nil], i1)).to eq({'' => adapter_factory})
      end

      it "in the face of ambiguity, brings the most specific for required" do
        i12 = stub_interface(i1)
        subject.register([i1], nil, '', &other_adapter_factory)
        subject.register([i12], nil, '', &adapter_factory)
        expect(subject.lookup_all([i12], nil)).to eq({'' => adapter_factory})
      end

      it "in the face of ambiguity, brings the most specific for provided" do
        i12 = stub_interface(i1)
        subject.register([nil], i1, '', &other_adapter_factory)
        subject.register([nil], i12, '', &adapter_factory)
        expect(subject.lookup_all([nil], i12)).to eq({'' => adapter_factory})
      end

      it "miss adapter factory if none matches" do
        subject.register([i1], nil, '', &adapter_factory)
        expect(subject.lookup_all([i2], nil)).to be_empty
      end
    end

    describe "#unregister" do
      it "doesn't complain when unregistering empty registry" do
        expect { subject.unregister([nil], nil, '') }.to_not raise_error
      end

      it "keeps registered if required doesn't match on unregistration" do
        subject.register([i1], nil, '', &adapter_factory)
        subject.unregister([i2], nil, '')
        expect(
          subject.first(required: [i1], provided: nil, name: '')
        ).to be adapter_factory
      end

      it "keeps registered if provided doesn't match on unregistration" do
        subject.register([nil], i1, '', &adapter_factory)
        subject.unregister([nil], i2, '')
        expect(
          subject.first(required: [nil], provided: i1, name: '')
        ).to be adapter_factory
      end

      it "keeps registered if name doesn't match on unregistration" do
        subject.register([i1], nil, '', &adapter_factory)
        subject.unregister([i1], nil, 'other name')
        expect(
          subject.first(required: [i1], provided: nil, name: '')
        ).to be adapter_factory
      end

      it "keeps registered if value is passed but doesn't match on "\
         "unregistration" do
        subject.register([i1], nil, '', &adapter_factory)
        subject.unregister([i1], nil, '', stub)
        expect(
          subject.first(required: [i1], provided: nil, name: '')
        ).to be adapter_factory
      end

      it "unregisters if value not passed and everything else matches "\
         "previous registration" do
        subject.register([i1], nil, '', &adapter_factory)
        subject.unregister([i1], nil, '')
        expect(
          subject.first(required: [i1], provided: nil, name: '')
        ).to be_nil
      end

      context "when using [nil] and nil for required and provided" do
        it "defaults to most simple single adapter" do
          subject.register([Interface], Interface, '', &adapter_factory)
          subject.unregister([nil], nil, '')
          expect(subject.first).to be_nil
        end
      end

      context "when using nil and nil for required and provided" do
        it "defaults to most simple single adapter" do
          subject.register([Interface], Interface, '', &adapter_factory)
          subject.unregister(nil, nil, '')
          expect(subject.first).to be_nil
        end
      end
    end
  end
end
