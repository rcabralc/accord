require 'accord/interface'
require 'accord/base_registry'

module Accord
  class AdapterLookup < BaseLookup
    def first(required, provided, name='')
      extendor = extendors.get(provided)
      return unless extendor
      return unless result = hash.detect_expansion(required) { |s| s.ancestors }
      available = extendor.compact_map { |i| result[i] }
      (available.detect { |h| h[name] } || {})[name]
    end

    def all(required, provided)
      extendor = extendors.get(provided)
      return {} unless extendor
      hashes = hash.select_expansions(required + [provided]) do |key|
        next key.ancestors.reverse if required.include?(key)
        extendor.current.reverse
      end
      hashes.inject({}) { |result, h| result.merge(h) }
    end
  end

  class AdapterRegistry < BaseRegistry
    def self.lookup_class
      AdapterLookup
    end

    def register(required, provided, name='', &value)
      raise ArgumentError, "cannot register without a block" unless value
      required = normalize_interfaces(required || [nil])
      provided ||= Interface
      registrations.by_order(required.size)[[required, provided, name]] = value
    end

    def unregister(required, provided, name, value=nil)
      required = normalize_interfaces(required || [nil])
      provided ||= Interface

      lookup = registrations.by_order(required.size)
      key = [required, provided, name]
      old = lookup[key]

      return if old.nil?
      return if !value.nil? && !old.equal?(value)

      lookup.delete(key)
    end

    def first(options={})
      required = normalize_interfaces(options[:required] || [nil])
      provided = options[:provided] || Interface
      name     = options[:name] || ''
      registrations.by_order(required.size)[[required, provided, name]]
    end

    def all(options={})
      required = normalize_interfaces(options[:required] || [nil])
      provided = options[:provided] || Interface
      registrations.by_order(required.size).partial(required, provided)
    end

    def lookup(required, provided, *args)
      required = normalize_interfaces(required || [nil])
      provided ||= Interface
      options  = args.last.is_a?(Hash) ? args.pop : {}
      name     = args.last || ''
      default  = options.delete(:default)
      lookup   = registrations.by_order(required.size)
      lookup.first(required, provided, name) || default
    end

    def lookup_all(required, provided)
      required = normalize_interfaces(required || [nil])
      provided ||= Interface
      lookup   = registrations.by_order(required.size)
      lookup.all(required, provided)
    end

    def get(objects, provided, *args)
      options = args.last.is_a?(Hash) ? args.pop : {}
      name    = args.last || ''
      default = options.delete(:default)
      factory = lookup(map_provided_by(objects), provided, name, options)
      return (factory.call(*objects) || default) if factory
      default
    end
  end

  class << self
    def install_default_adapter_hook
      install_adapter_hook(Proc.new { |provided, *objects|
        default_adapter_registry.get(objects, provided)
      })
    end

    def clear_default_adapter_hook
      @default_adapter_registry = nil
    end

    def default_adapter_registry
      @default_adapter_registry ||= AdapterRegistry.new
    end
  end
end
