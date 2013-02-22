module Accord
  class RO
    CACHE_IVAR_NAME = :@_accord_ro_cache_

    def initialize(item, &block)
      @item = item
      @block = block
    end

    def resolve
      cached = from_cache
      return cached if cached

      bases = block.call(item)
      bases_ros = bases.map { |b| RO.new(b, &block).resolve }
      merge([[item]] + bases_ros + [bases]).tap { |ro| cache(ro) }
    end

    def changed
      invalidate
      resolve
    end

  private

    attr_reader :item
    attr_reader :block

    def from_cache
      item.instance_variable_get(CACHE_IVAR_NAME)
    end

    def cache(ro)
      item.instance_variable_set(CACHE_IVAR_NAME, ro)
    end

    def invalidate
      item.instance_variable_set(CACHE_IVAR_NAME, nil)
    end

    def merge(sequences)
      sequences = sequences.map { |seq| seq.dup }
      result = []

      loop do
        sequences.delete_if { |sequence| sequence.empty? }
        return result unless sequences.any?

        good = sequences.detect do |current|
          sequences.all? { |seq| !tail(seq).include?(current.first) }
        end

        raise TypeError, "inconsistent hierarchy" unless good

        head = good.first
        sequences.each { |seq| seq.shift if seq.first == head }
        result << head
      end
    end

    def tail(array)
      array[1..-1] || []
    end
  end
end
