require 'spec_helper'
require 'accord/interface_methods'

module Accord
  describe InterfaceMethods do
    let(:interface) { stub }
    let(:sig_info)  { stub(:param => nil, :block => nil, :splat => nil) }

    subject { InterfaceMethods.new(interface) }

    before do
      stub_const("Accord::SignatureInfo", stub)
      Accord::SignatureInfo.stub(:new).and_return(sig_info)
    end

    it "doesn't has any method added by default" do
      expect(subject[:m]).to be_nil
    end

    describe "#add" do
      it "adds the method" do
        subject.add(:m)
        expect(subject[:m].name).to eq 'm' # Method names are strings.
      end

      it "adds the signature info to the method" do
        subject.add(:m)
        expect(subject[:m].signature_info).to be sig_info
      end

      it "assigns the interface to the method object" do
        subject.add(:m)
        expect(subject[:m].interface).to be interface
      end

      context "using :params option" do
        context "to add a regular argument" do
          it "creates a param in the signature info" do
            sig_info.should_receive(:param).with(:foo)
            subject.add(:m, params: :foo)
          end
        end

        context "to add a splat argument" do
          it "creates a splat in the signature info" do
            sig_info.should_receive(:splat).with(:foo)
            subject.add(:m, params: :"*foo")
          end
        end

        context "to add a block argument" do
          it "creates a block argument in the signature info" do
            sig_info.should_receive(:block).with(:foo)
            subject.add(:m, params: :"&foo")
          end
        end
      end

      context "using block" do
        context "to add a regular argument" do
          it "creates a param in the signature info" do
            sig_info.should_receive(:param).with(:foo)
            subject.add(:m) { param :foo }
          end
        end

        context "to add a splat argument" do
          it "creates a splat in the signature info" do
            sig_info.should_receive(:splat).with(:foo)
            subject.add(:m) { splat :foo }
          end
        end

        context "to add a block argument" do
          it "creates a block argument in the signature info" do
            sig_info.should_receive(:block).with(:foo)
            subject.add(:m) { block :foo }
          end
        end
      end
    end

    describe "#names" do
      it "return added names as symbols" do
        subject.add(:m)
        expect(subject.names).to eq [:m]
      end
    end

    describe "#added?" do
      it "returns true if the method was added" do
        subject.add(:m)
        expect(subject).to be_added(:m)
      end

      it "returns false if the method was not added" do
        expect(subject).to_not be_added(:m)
      end
    end

    describe "#each" do
      it "iterates over all methods" do
        names = []
        methods = []

        subject.add(:m)
        subject.add(:n)

        subject.each { |name, method| names << name; methods << method }

        expect(names).to eq [:m, :n]
        expect(methods.map(&:name)).to eq ['m', 'n']
      end
    end
  end
end
