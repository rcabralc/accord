require 'spec_helper'
require 'accord/extendor'

module Accord
  describe Extendor do
    subject { Extendor.new }

    it { should be_empty }
    its(:current) { should be_empty }

    specify "adding interface to extendor" do
      interface = stub
      subject.add(interface)
      expect(subject.current).to eq [interface]
    end

    specify "adding interface makes it not empty" do
      subject.add(stub)
      expect(subject).to_not be_empty
      expect(subject.current).to_not be_empty
    end

    specify "adds an interface only once" do
      interface = stub
      subject.add(interface)
      subject.add(interface)
      expect(subject.current).to eq [interface]
    end

    describe "adding in details" do
      let(:interface1) { stub }
      let(:interface2) { stub(:extends? => true) }
      let(:extending)  { stub }

      before do
        subject.add(interface1)
        subject.add(interface2)
      end

      context "when added interface extends some" do
        before do
          extending.stub(:extends?).with(interface1).and_return(true)
          extending.stub(:extends?).with(interface2).and_return(false)
          subject.add(extending)
        end

        it "adds it after the ones it extends" do
          expect(subject.current).to eq [interface1, extending, interface2]
        end
      end

      context "when added interface extends none" do
        before do
          extending.stub(:extends?).with(interface1).and_return(false)
          extending.stub(:extends?).with(interface2).and_return(false)
          subject.add(extending)
        end

        it "adds it in the beginning" do
          expect(subject.current).to eq [extending, interface1, interface2]
        end
      end

      context "when added interface extends all" do
        before do
          extending.stub(:extends?).with(interface1).and_return(true)
          extending.stub(:extends?).with(interface2).and_return(true)
          subject.add(extending)
        end

        it "adds it in the end" do
          expect(subject.current).to eq [interface1, interface2, extending]
        end
      end
    end

    specify "modifying current doesn't alter state of extendor" do
      subject.current << stub
      expect(subject.current).to be_empty

      interface = stub
      subject.add(interface)
      subject.current << stub
      expect(subject.current.size).to eq 1

      subject.current.delete(interface)
      expect(subject.current.size).to eq 1
    end

    specify "deleting is done using #delete" do
      interface = stub
      subject.add(interface)
      subject.delete(interface)
      expect(subject).to be_empty
    end

    specify "deleting interface on empty extendor" do
      subject.delete(stub)
      expect(subject).to be_empty
    end

    specify "deleting doesn't break if deleting already deleted interface" do
      interface1 = stub
      interface2 = stub(:extends? => false)
      subject.add(interface1)
      subject.add(interface2)

      subject.delete(interface1)
      subject.delete(interface1)
      subject.delete(interface1)

      expect(subject.current).to eq [interface2]
    end

    describe "#compact_map" do
      it "maps the current interfaces to the given block" do
        interface1 = stub
        interface2 = stub(:extends? => false)
        subject.add(interface1)
        subject.add(interface2)

        result = subject.compact_map { |i| i.object_id }

        expect(result).to include(interface1.object_id)
        expect(result).to include(interface2.object_id)
      end

      it "discards nil entries when mapping" do
        interface1 = stub
        interface2 = stub(:extends? => false)
        subject.add(interface1)
        subject.add(interface2)

        result = subject.compact_map { |i| i.equal?(interface1) ? nil : i }

        expect(result).to_not include(interface1)
        expect(result).to     include(interface2)
      end

      it "maps in the order they were left" do
        interface1 = stub
        interface2 = stub
        interface3 = stub

        interface2.stub(:extends?).with(interface1).and_return(false)
        interface3.stub(:extends?).with(interface1).and_return(true)
        interface3.stub(:extends?).with(interface2).and_return(false)

        subject.add(interface1)
        subject.add(interface2)
        subject.add(interface3)

        interfaces = subject.compact_map { |i| i }

        expect(interfaces).to eq [interface1, interface3, interface2]
      end
    end

    describe "#flat_map" do
      it "maps the current interfaces to the given block" do
        interface1 = stub
        interface2 = stub(:extends? => false)
        subject.add(interface1)
        subject.add(interface2)

        result = subject.flat_map { |i| i.object_id }

        expect(result).to include(interface1.object_id)
        expect(result).to include(interface2.object_id)
      end

      it "expands arrays returned by block" do
        interface1 = stub
        interface2 = stub(:extends? => false)
        subject.add(interface1)
        subject.add(interface2)

        result = subject.flat_map { |i| [i] }

        expect(result).to include(interface1)
        expect(result).to include(interface2)
      end

      it "maps in the order they were left" do
        interface1 = stub
        interface2 = stub
        interface3 = stub

        interface2.stub(:extends?).with(interface1).and_return(false)
        interface3.stub(:extends?).with(interface1).and_return(true)
        interface3.stub(:extends?).with(interface2).and_return(false)

        subject.add(interface1)
        subject.add(interface2)
        subject.add(interface3)

        interfaces = subject.flat_map { |i| i }

        expect(interfaces).to eq [interface1, interface3, interface2]
      end
    end
  end
end
