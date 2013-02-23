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

    def splat(name)
      arguments << { name: name.to_sym, splat: true }
    end

    def block(name=nil)
      if name
        @block = name.to_sym
      else
        @block
      end
    end

    def match?(params)
      args = normalized_arguments
      match_without_all_required_args(args, params) ||
        match_without_all_required_args(args, without_last_defaults(params))
    end

  private

    def normalized_arguments
      (arguments + (block ? [{ name: block, block: true }] : [])).map do |arg|
        if arg[:splat]
          :rest
        elsif arg[:block]
          :block
        elsif arg.has_key?(:default)
          :opt
        else
          :req
        end
      end
    end

    def without_last_defaults(params)
      params = params.dup
      params.pop if params.any? && params.last.first == :block
      params.pop while params.any? && params.last.first == :opt
      params
    end

    def match_without_all_required_args(args, params)
      return false unless args.size == params.size
      args.each_with_index do |arg, index|
        if arg == :req && [:req, :opt].include?(params[index].first)
          next
        elsif params[index].first == arg
          next
        end
        return false
      end
      true
    end
  end
end
