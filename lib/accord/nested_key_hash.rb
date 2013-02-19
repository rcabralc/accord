module Accord
  class NestedKeyHash
    def [](keys)
      keys = keys.dup
      last_key = keys.pop
      last_hash = keys.inject(hash) do |partial, key|
        return nil unless partial.has_key?(key)
        partial[key]
      end
      last_hash[last_key]
    end

    def []=(keys, value)
      keys = keys.dup
      last_key = keys.pop
      last_hash = keys.inject(hash) { |partial, key| partial[key] ||= {} }
      last_hash[last_key] = value
    end

    def delete(keys)
      keys = keys.dup
      last_hash = {}
      result = nil
      while last_hash.size == 0 && keys.any?
        last_key = keys.pop
        last_hash = keys.inject(hash) { |partial, key| partial[key] || {} }
        partial_result = last_hash.delete(last_key)
        result ||= partial_result
      end
      result
    end

    def detect_expansion(keys)
      keys.inject(hash) do |partial, part|
        expansion = yield(part)
        valid_key = expansion.detect { |key| partial.has_key?(key) }
        return unless valid_key
        partial[valid_key]
      end
    end

    def select_expansions(keys, partial=hash, results=[], &block)
      if keys.size == 1
        expansion = block.call(keys.first)
        valid_expansions = expansion.select { |key| partial.has_key?(key) }
        valid_expansions.each { |key| results << partial[key] }
        return results
      end
      keys = keys.dup
      first_key = keys.shift
      expansion = block.call(first_key)
      valid_expansions = expansion.select { |key| partial.has_key?(key) }
      return results unless valid_expansions.any?
      valid_expansions.each do |key|
        select_expansions(keys, partial[key], results, &block)
      end
      results
    end

  private

    def hash
      @hash ||= {}
    end
  end
end
