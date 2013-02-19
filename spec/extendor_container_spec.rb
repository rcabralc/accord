require 'spec_helper'
require 'accord/extendor_container'

module Accord
  describe ExtendorContainer do
    let(:extendor) { stub }
    let(:i1)       { stub }
    let(:i2)       { stub }
    let(:provided) { stub }

    let(:extendor_class) do
      Class.new do
        attr_reader :current
        def initialize
          @current = []
        end
        def add(interface)
          current << interface
        end
        def delete(interface)
          current.delete(interface)
        end
        def empty?
          current.empty?
        end
      end
    end

    subject { ExtendorContainer.new }

    before do
      provided.stub(:iro => [provided, i1, i2])
      stub_const('Accord::Extendor', extendor_class)
    end

    it "starts clean" do
      expect(subject.get(provided).current).to be_empty
    end

    it "reports when a given interface is not set" do
      expect(subject.has?(provided)).to be_false
    end

    it "adds an interface for each extendor of its resolution order" do
      subject.add(provided)
      expect(subject.get(provided).current).to include(provided)
      expect(subject.get(i1).current).to include(provided)
      expect(subject.get(i2).current).to include(provided)
    end

    it "reports when a given interface is set" do
      subject.add(provided)
      expect(subject.has?(provided)).to be_true
      expect(subject.has?(i1)).to be_true
      expect(subject.has?(i2)).to be_true
    end

    it "accumulates interfaces while adding" do
      other = stub
      other.stub(:iro => [other, i1, i2])

      subject.add(provided)
      subject.add(other)

      expect(subject.get(provided).current).to eq [provided]
      expect(subject.get(other).current).to eq [other]

      expect(subject.get(i1).current).to include(provided)
      expect(subject.get(i1).current).to include(other)

      expect(subject.get(i2).current).to include(provided)
      expect(subject.get(i2).current).to include(other)
    end

    it "deletes interfaces" do
      other = stub
      other.stub(:iro => [other, i1, i2])

      subject.add(provided)
      subject.add(other)
      subject.delete(provided)

      expect(subject.get(provided).current).to eq []
      expect(subject.get(other).current).to eq [other]

      expect(subject.get(i1).current).to_not include(provided)
      expect(subject.get(i1).current).to include(other)

      expect(subject.get(i2).current).to_not include(provided)
      expect(subject.get(i2).current).to include(other)
    end

    it "reports when an interface has been deleted" do
      subject.add(provided)
      subject.delete(provided)
      expect(subject.has?(provided)).to be_false
      expect(subject.has?(i1)).to be_false
      expect(subject.has?(i2)).to be_false
    end
  end
end
