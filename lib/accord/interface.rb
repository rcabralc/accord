require 'accord/specification'
require 'accord/declarations'

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
  end

  class InterfaceClass < Accord::Specification
    def initialize(name, bases=[], params={})
      super(bases)
      @name = name
      @doc = params[:doc]
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

  protected

    def changed(originally_changed)
      @iro = nil
      super
    end
  end

  Interface = InterfaceClass.new(:'Accord::Interface')
end
