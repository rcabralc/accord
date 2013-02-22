module Accord
  class InterfaceMethod
    attr_reader :name, :interface, :signature_info

    def initialize(interface, name, signature_info)
      @interface = interface
      @name = name.to_s
      @signature_info = signature_info
    end

    def tags
      @tags ||= Tags.new
    end
  end

  class InterfaceMethods
    def initialize(interface)
      @interface = interface
      @hash = {}
      @order = []
    end

    def add(method_name, options={}, &block)
      method_name = method_name.to_sym
      @order << method_name unless @order.include?(method_name)
      @hash[method_name] = self.class.make_method(
        @interface, method_name, options, block
      )
    end

    def names
      @order.dup
    end

    def [](name)
      @hash[name.to_sym]
    end

    def added?(name)
      names.include?(name)
    end

    def each
      @order.each { |name| yield(name, @hash[name]) }
    end

    def self.make_method(interface, name, options, block)
      arguments = SignatureInfo.new
      if args = options[:params]
        raise ArgumentError,
          "no block is expected when using option `:param`." if block
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
