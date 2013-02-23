require 'set'
require 'accord/exceptions'
require 'accord/specification'
require 'accord/declarations'
require 'accord/tags'
require 'accord/signature_info'
require 'accord/interface_body'
require 'accord/interface_members'

module Accord
  class << self
    def install_adapter_hook(hook)
      adapter_hooks << hook
    end

    def clear_adapter_hooks
      adapter_hooks.clear
    end

    def adapter_hooks
      @adapter_hooks ||= []
    end

    def Interface(*args, &block)
      first_arg = args.shift
      if first_arg.is_a?(String) || first_arg.is_a?(Symbol)
        const_name = nil
        top_level = nil
        name = first_arg.to_s
      else
        const_name = args.shift.to_s
        top_level = first_arg
        name = top_level.name + '::' + const_name
      end

      interface = InterfaceClass.new(name, [Interface])

      InterfaceBody.run(interface, &block)

      top_level.const_set(const_name, interface) if const_name
      interface
    end
  end

  class InterfaceInvariants
    def initialize(interface)
      @interface = interface
      @invariants = {}
    end

    def add(invariant_name, &block)
      @invariants[invariant_name.to_sym] = block
    end

    def run(object, errors)
      @invariants.each do |invariant_name, block|
        block.call(object, errors)
      end
    end
  end

  class InterfaceClass < Accord::Specification
    attr_accessor :doc

    def initialize(name, bases=[])
      super(bases)
      @name = name.to_s
    end

    def name
      @name
    end

    def each_interface
      yield(self)
    end

    def iro
      @iro ||= ancestors.select { |spec| spec.is_a?(InterfaceClass) }
    end

    def inspect
      "<Interface #{name}>"
    end

    def adapt(*objects)
      Accord.adapter_hooks.each do |hook|
        result = hook.call(self, *objects)
        return result if result
      end
      nil
    end

    def adapt!(*objects)
      adapt(*objects).tap do |result|
        raise TypeError, "could not adapt: #{objects.inspect}" if result.nil?
      end
    end

    def provided_by?(object)
      Accord::Declarations.provided_by(object).extends?(self)
    end

    def implemented_by?(cls_or_mod)
      Accord::Declarations.implemented_by(cls_or_mod).extends?(self)
    end

    def members
      @members ||= InterfaceMembers.new(self)
    end

    def invariants
      @invariants ||= InterfaceInvariants.new(self)
    end

    def member_names
      iro.reverse.each_with_object([]) do |i, names|
        i.members.names.each do |name|
          names << name unless names.include?(name)
        end
      end
    end

    def own_member_names
      members.names
    end

    def [](name)
      owner = iro.detect { |i| i.owns?(name) }
      owner.members[name] if owner
    end

    def defined?(name)
      iro.any? { |i| i.owns?(name) }
    end

    def owns?(name)
      members.added?(name)
    end

    def each
      member_names.each do |name|
        yield(name, self[name])
      end
    end

    def assert_invariants?(object, errors=nil)
      errors ||= []
      (iro - [self]).each { |i| i.assert_invariants?(object, errors) }
      invariants.run(object, errors)
      errors.empty?
    end

    def assert_invariants(object, errors=nil)
      raise Invalid unless assert_invariants?(object, errors)
    end

    def tags
      @tags ||= Tags.new
    end

    def verify_object(object)
      raise DoesNotImplement.new(self) unless provided_by?(object)

      each do |name, member|
        raise BrokenImplementation.new(self, name) unless \
          member.compatible_with_object?(object)
      end
    end

    def verify_module(mod)
      raise DoesNotImplement.new(self) unless implemented_by?(mod)

      each do |name, member|
        raise BrokenImplementation.new(self, name) unless \
          member.compatible_with_module?(mod)
      end
    end

  protected

    def changed(originally_changed)
      @iro = nil
      super
    end
  end

  Interface = InterfaceClass.new(:'Accord::Interface')
end
