module Accord
  UNSPECIFIED = Object.new.tap do |o|
    o.define_singleton_method(:inspect) { 'UNSPECIFIED' }
  end

  class SignatureInfo
    def arguments
      @arguments ||= []
    end

    def param(arg)
      if arg.is_a?(Symbol) || arg.is_a?(String)
        arg = { name: arg.to_sym }
      elsif arg.is_a?(Hash) && arg.size == 1
        arg = { name: arg.keys.first, default: arg.values.first }
      else
        raise ArgumentError, "bad argument: #{arg.inspect}."
      end
      arguments << arg
    end

    def splat(name=nil)
      if name
        @splat = name.to_sym
      else
        @splat
      end
    end

    def block(name=nil)
      if name
        @block = name.to_sym
      else
        @block
      end
    end
  end
end
