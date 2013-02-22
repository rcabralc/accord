require 'spec_helper'
require 'accord/tags'

module Accord
  describe Tags do
    subject { Tags.new }

    it "returns nil if a tag isn't set" do
      expect(subject[:not_set]).to be_nil
    end

    it "sets and gets" do
      subject[:tag] = 'value'
      expect(subject[:tag]).to eq 'value'
    end

    it "treats symbols and strings as same" do
      subject[:tag] = 'value'
      expect(subject['tag']).to eq 'value'
    end

    describe "#fetch" do
      it "returns the tag it it is set" do
        subject[:tag] = 'value'
        expect(subject.fetch(:tag)).to eq 'value'
      end

      it "returns a default value if tag isn't set and default is given" do
        default = Object.new
        expect(subject.fetch(:tag, default)).to be default
      end

      it "raises error if the tag isn't set and a default is not given" do
        expect { subject.fetch(:tag) }.to raise_error(ArgumentError)
      end
    end
  end
end
