require 'accord/declarations'
require 'accord/extendor_container'
require 'accord/nested_key_hash'

module Accord
  class Registrations
    def initialize(lookup_class)
      @lookup_class = lookup_class
    end

    def by_order order
      hash[order] ||= @lookup_class.new(order, extendors)
    end

  private

    def hash
      @hash ||= {}
    end

    def extendors
      @extendors ||= ExtendorContainer.new
    end
  end

  class BaseLookup
    attr_reader :order, :extendors, :hash

    def initialize(order, extendors)
      @order = order
      @extendors = extendors
      @hash = NestedKeyHash.new
      super()
    end

    def [](key)
      required, provided, name = key
      hash[required + [provided] + [name]]
    end

    def []=(key, value)
      required, provided, name = key
      extendors.add(provided)
      hash[required + [provided] + [name]] = value
    end

    def partial(required, provided)
      (hash[required + [provided]] || []).sort_by { |name, value| name }
    end

    def delete(key)
      required, provided, name = key
      extendors.delete(provided)
      hash.delete(required + [provided] + [name])
    end
  end

  class BaseRegistry
    def map_provided_by(objects)
      objects.map { |object| Accord::Declarations.provided_by(object) }
    end

  private

    def registrations
      @registrations ||= Registrations.new(self.class.lookup_class)
    end

    def normalize_interfaces(interfaces)
      interfaces.map { |i| i.nil?? Accord::Interface : i }
    end
  end
end
