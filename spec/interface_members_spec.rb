require 'spec_helper'
require 'accord/interface_members'

module Accord
  describe InterfaceMembers do
    let(:interface) { stub }
    let(:member)    { stub }

    subject { InterfaceMembers.new(interface) }

    it "doesn't have any member added by default" do
      expect(subject[:m]).to be_nil
    end

    describe "#add" do
      it "adds the member" do
        subject.add(:m, member)
        expect(subject[:m]).to be member
      end
    end

    describe "#names" do
      it "return added names as symbols" do
        subject.add(:m, member)
        expect(subject.names).to eq [:m]
      end
    end

    describe "#added?" do
      it "returns true if the method was added" do
        subject.add(:m, member)
        expect(subject).to be_added(:m)
      end

      it "returns false if the method was not added" do
        expect(subject).to_not be_added(:m)
      end
    end

    describe "#each" do
      it "iterates over all members" do
        names = []
        members = []

        m, n = stub, stub

        subject.add(:m, m)
        subject.add(:n, n)

        subject.each { |name, member| names << name; members << member }

        expect(names).to eq [:m, :n]
        expect(members).to eq [m, n]
      end
    end
  end
end
