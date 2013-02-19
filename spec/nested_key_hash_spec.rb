require 'spec_helper'
require 'accord/nested_key_hash'

module Accord
  describe NestedKeyHash do
    subject { NestedKeyHash.new }

    let(:k1) { 'key 1' }
    let(:k2) { 'key 2' }
    let(:k3) { 'key 3' }

    let(:key) { [k1, k2, k3] }

    specify "empty hash returns nil" do
      expect(subject[key]).to be_nil
    end

    it "adds a value using a composed key" do
      value = stub
      subject[key] = value
      expect(subject[key]).to be value
    end

    specify "different keys store different values" do
      value1 = stub
      value2 = stub
      subject[[k1, k2, k3]] = value1
      subject[[k3, k2, k1]] = value2

      expect(subject[[k1, k2, k3]]).to be value1
      expect(subject[[k3, k2, k1]]).to be value2
    end

    it "overwrites a value when using the same key" do
      old_value = stub
      new_value = stub
      subject[key] = old_value
      subject[key] = new_value
      expect(subject[key]).to be new_value
    end

    specify "keys not prefixing other already in use returns nil" do
      subject[key] = 'a value'
      expect(subject[[k2, k1, k3]]).to be_nil
    end

    specify "prefix keys returns hash containing the remaining keys nested" do
      value = stub
      subject[key] = value
      expect(subject[[k1]]).to eq({ k2 => { k3 => value } })
    end

    it "deletes a key" do
      subject[key] = 'a value'
      subject.delete(key)
      expect(subject[key]).to be_nil
    end

    specify "deleting returns the deleted value" do
      value = stub
      subject[key] = value
      result = subject.delete(key)
      expect(result).to be value
    end

    specify "deleting a key removes intermediate empty hashes" do
      subject[key] = 'a value'
      subject.delete(key)
      expect(subject[[k1]]).to be_nil
      expect(subject[[k1, k2]]).to be_nil
    end

    specify "deleting a key keeps intermediate non-empty hashes" do
      value, another_value, k4, k5 = stub, stub, 'key 4', 'key 5'
      subject[[k1, k2, k3, k4]] = value
      subject[[k1, k2, k4, k5]] = another_value
      subject.delete([k1, k2, k3, k4])

      expect(subject[[k1, k2, k4, k5]]).to be another_value
    end

    describe "key lookup with expansion" do

      let(:k11) { stub }
      let(:k12) { stub }
      let(:k13) { stub }
      let(:k21) { stub }
      let(:k22) { stub }
      let(:k23) { stub }

      let(:expansions) do
        {
          k1 => [k11, k12, k13],
          k2 => [k21, k22, k23]
        }
      end

      describe "#detect_expansion" do
        it "hits the value with valid expansion" do
          subject[[k11, k22]] = 'value'
          result = subject.detect_expansion([k1, k2]) do |k|
            expansions[k]
          end
          expect(result).to eq 'value'
        end

        it "misses the value with invalid expansion" do
          subject[[k11, k12]] = 'value'
          result = subject.detect_expansion([k1, k2]) do |k|
            expansions[k]
          end
          expect(result).to be_nil
        end
      end

      describe "#select_expansions" do
        it "hits the values matching some valid expansion" do
          subject[[k11, k22]] = 'value'
          subject[[k12, k21]] = 'other value'

          result = subject.select_expansions([k1, k2]) do |k|
            expansions[k]
          end
          expect(result).to eq ['value', 'other value']
        end

        it "misses if no valid expansion is found" do
          subject[[k11, k12]] = 'value'
          subject[[k11, k13]] = 'other value'

          result = subject.select_expansions([k1, k2]) do |k|
            expansions[k]
          end

          expect(result).to be_empty
        end
      end
    end
  end
end
