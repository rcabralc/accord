require 'spec_helper'
require 'accord/signature_info'

module Accord
  describe SignatureInfo do
    subject { SignatureInfo.new }

    describe "#param" do
      it "adds new arguments to #arguments" do
        subject.param(:foo)
        expect(subject.arguments).to eq [ { name: :foo } ]
      end

      it "converts names to symbols" do
        subject.param('foo')
        expect(subject.arguments).to eq [ { name: :foo } ]
      end

      it "accepts a unitary hash which holds a default value" do
        subject.param(foo: :bar)
        expect(subject.arguments).to eq [ { name: :foo, default: :bar } ]
      end

      it "rejects anything else" do
        expect { subject.param(1) }.to raise_error(ArgumentError)
      end
    end

    describe "#splat" do
      context "with a symbol" do
        it "adds a splat argument" do
          subject.splat(:foo)
          expect(subject.arguments).to eq [ { name: :foo, splat: true } ]
        end
      end

      context "with a string" do
        it "sets a splat argument, as a symbol" do
          subject.splat('foo')
          expect(subject.arguments).to eq [ { name: :foo, splat: true } ]
        end
      end
    end

    describe "#block" do
      it "returns nil if no splat argument has been set" do
        expect(subject.block).to be_nil
      end

      context "with a symbol" do
        it "sets a block argument" do
          subject.block(:foo)
          expect(subject.block).to eq :foo
        end
      end

      context "with a string" do
        it "sets a block argument, as a symbol" do
          subject.block('foo')
          expect(subject.block).to eq :foo
        end
      end
    end
  end
end
