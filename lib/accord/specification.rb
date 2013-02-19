require 'set'

module Accord
  class SpecificationAncestry
    include Enumerable

    def initialize(spec, bases)
      @spec = spec
      @bases = bases
      @results ||=
        begin
          seen = Set.new([@spec])
          results = [@spec]
          @bases.each do |base|
            base.ancestry.each do |spec|
              next if seen.include?(spec)
              seen << spec
              results << spec
            end
          end
          results
        end
    end

    def each
      @results.each { |result| yield(result) }
    end
  end

  class Specification
    attr_reader :ancestry

    def initialize(bases=[])
      @dependents = Set.new
      self.bases = bases
    end

    def subscribe(dependent)
      @dependents << dependent
    end

    def unsubscribe(dependent)
      @dependents.delete(dependent)
    end

    def bases
      @bases || []
    end

    def bases= new_bases
      new_bases = new_bases.uniq
      new_bases.each do |base|
        raise TypeError,
          'cannot use something other than Specification as a base' \
          unless base.is_a?(Specification)
      end

      bases.each { |base| base.unsubscribe(self) }
      new_bases.each { |base| base.subscribe(self) }

      @bases = new_bases

      changed(self)
    end

    def changed(originally_changed)
      @ancestry = SpecificationAncestry.new(self, bases)
      @dependents.each do |dependent|
        dependent.changed(originally_changed)
      end
    end

    def each_interface
      seen = Set.new
      @bases.each do |base|
        base.each_interface do |interface|
          next if seen.include?(interface)
          seen << interface
          yield(interface)
        end
      end
    end

    def interfaces
      enum_for(:each_interface).to_a
    end

    def ancestors
      @ancestry.to_a
    end

    def extends?(other)
      @ancestry.include?(other)
    end

    def inspect
      "<Specification bases=#{bases.inspect}>"
    end
  end
end
