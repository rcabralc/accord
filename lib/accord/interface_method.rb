require 'accord/tags'

module Accord
  class InterfaceMethod
    attr_reader :name, :interface, :signature_info

    def initialize(interface, name, signature_info)
      @interface = interface
      @name = name.to_sym
      @signature_info = signature_info
    end

    def tags
      @tags ||= Tags.new
    end

    def compatible_with_object?(object)
      return false unless object.respond_to?(name)
      signature_info.match?(object.method(name).parameters)
    end

    def compatible_with_module?(mod)
      return false unless mod.instance_methods.include?(name)
      signature_info.match?(mod.instance_method(name).parameters)
    end
  end
end
