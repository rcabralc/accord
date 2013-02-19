require 'accord/interface'
require 'accord/base_registry'

module Accord
  class SubscriberLookup < BaseLookup
    def all(required, provided)
      extendor = extendors.get(provided)
      return [] unless extendor
      hash.select_expansions(required + [provided, '']) do |key|
        if required.include?(key)
          key.ancestors.reverse
        elsif key.equal?(provided)
          extendor.current.reverse
        else
          ['']
        end
      end.flatten
    end
  end

  class SubscriptionRegistry < BaseRegistry
    def self.lookup_class
      SubscriberLookup
    end

    def subscribe(required, provided, &value)
      raise ArgumentError, "cannot subscribe without a block" unless value
      required = normalize_interfaces(required || [nil])
      provided ||= Interface
      key = [required, provided, '']
      (registrations.by_order(required.size)[key] ||= []) << value
    end

    def select(options={})
      required = normalize_interfaces(options[:required] || [nil])
      provided = options[:provided] || Interface
      registrations.by_order(required.size)[[required, provided, '']] || []
    end

    def unsubscribe(required, provided, value=nil)
      required = normalize_interfaces(required || [nil])
      provided ||= Interface
      lookup = registrations.by_order(required.size)
      key = [required, provided, '']
      old = lookup[key] || []

      return if old.empty?

      new = value.nil?? [] : old.select { |v| !v.equal?(value) }
      if new.any?
        lookup[key] = new
      else
        lookup.delete(key)
      end
    end

    def lookup(required, provided)
      required = normalize_interfaces(required || [nil])
      provided ||= Interface
      lookup = registrations.by_order(required.size)
      lookup.all(required, provided)
    end

    def get(objects, provided=Interface)
      lookup(map_provided_by(objects), provided).map do |subscriber|
        subscriber.call(*objects)
      end.compact
    end

    def call(objects, provided=Interface)
      lookup(map_provided_by(objects), provided).each do |subscriber|
        subscriber.call(*objects)
      end
    end
  end
end
