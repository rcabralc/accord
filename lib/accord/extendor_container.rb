require 'accord/extendor'

module Accord
  class ExtendorContainer
    def get(interface)
      hash[interface] || Extendor.new
    end

    def add(provided)
      provided.iro.each do |interface|
        extendor = get(interface)
        extendor.add(provided)
        set(interface, extendor)
      end
    end

    def delete(provided)
      provided.iro.each do |interface|
        extendor = get(interface)
        extendor.delete(provided)
        set(interface, extendor)
      end
    end

    def has?(interface)
      hash.has_key?(interface)
    end

  private

    def set(interface, extendor)
      if extendor.empty?
        hash.delete(interface)
      else
        hash[interface] = extendor
      end
    end

    def hash
      @hash ||= {}
    end
  end
end
