require 'accord/interface_method'

module Accord
  class InterfaceBody
    attr_reader :interface

    def initialize(interface, bases, members, invariants)
      @interface = interface
      @bases = bases
      @members = members
      @invariants = invariants
    end

    def extends(*new_bases)
      new_bases.each do |base|
        @bases.unshift(base) unless @bases.include?(base)
      end
    end

    def responds_to(name, options={}, &block)
      method = self.class.make_method(interface, name, options, block)
      @members.add(name, method)
    end

    def invariant(invariant_name, &block)
      @invariants.add(invariant_name, &block)
    end

    def tags
      interface.tags
    end

    def self.run(interface, &block)
      bases = []
      members = interface.members
      invariants = interface.invariants

      body = new(interface, bases, members, invariants)
      body.instance_exec(&block) if block

      bases.unshift(Interface) if bases.empty?
      interface.bases = bases

      interface
    end

    def self.make_method(interface, name, options, block)
      arguments = SignatureInfo.new
      if args = options[:params]
        raise ArgumentError,
          "no block is expected when using option `:params`." if block
        args = [args] unless args.is_a?(Array)
        args.each do |arg|
          if arg.is_a?(Symbol)
            if arg.to_s.start_with?('&')
              arguments.block(arg.to_s.gsub(/^&/, '').to_sym)
            elsif arg.to_s.start_with?('*')
              arguments.splat(arg.to_s.gsub(/^\*/, '').to_sym)
            else
              arguments.param(arg)
            end
          else
            arguments.param(arg)
          end
        end
      elsif block
        arguments.instance_exec(&block)
      end

      InterfaceMethod.new(interface, name, arguments)
    end
  end
end
