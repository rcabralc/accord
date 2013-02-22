require 'set'
require 'accord/ro'

module Accord
  class Specification
    def initialize(*args)
      if args.size == 2 || args.first.is_a?(String) || args.first.is_a?(Symbol)
        @name = args.first.to_s
        bases = (args.size == 2 ? (args[1] || []) : [])
      else
        @name = '?'
        bases = args.first || []
      end
      @dependents = Set.new
      @ro = Accord::RO.new(self) { |spec| spec.bases }
      self.bases = bases
    end

    def bases
      (@bases || []).dup
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
      @ro.resolve
    end

    def extends?(other)
      ancestors.include?(other)
    end

    def inspect
      "<Specification #{@name.inspect}>"
    end

  protected

    def changed(originally_changed)
      @ro.changed
      @dependents.each do |dependent|
        dependent.changed(originally_changed)
      end
    end

    def subscribe(dependent)
      @dependents << dependent
    end

    def unsubscribe(dependent)
      @dependents.delete(dependent)
    end
  end
end
