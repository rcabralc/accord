module Accord
  class InterfaceBody
    attr_reader :interface

    def initialize(interface, bases, methods, invariants)
      @interface = interface
      @bases = bases
      @methods = methods
      @invariants = invariants
    end

    def extends(*new_bases)
      new_bases.each do |base|
        @bases.unshift(base) unless @bases.include?(base)
      end
    end

    def responds_to(*args, &block)
      @methods.add(*args, &block)
    end

    def invariant(invariant_name, &block)
      @invariants.add(invariant_name, &block)
    end

    def tags
      interface.tags
    end

    def self.run(interface, &block)
      bases = []
      methods = interface.methods
      invariants = interface.invariants

      body = new(interface, bases, methods, invariants)
      body.instance_exec(&block)

      bases.unshift(Interface) if bases.empty?
      interface.bases = bases

      interface
    end
  end
end
