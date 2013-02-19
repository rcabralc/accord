module Accord
  class Extendor
    def initialize
      @current = []
    end

    def add(new)
      return if @current.include?(new)
      @current = (
        @current.select { |i| new.extends?(i) } +
        [new] +
        @current.select { |i| !new.extends?(i) }
      )
    end

    def delete(old)
      @current.delete_if { |i| i.equal?(old) }
    end

    def empty?
      @current.empty?
    end

    def current
      @current.dup
    end

    def compact_map
      @current.map { |i| yield(i) }.compact
    end

    def flat_map
      @current.flat_map { |i| yield(i) }
    end
  end
end
