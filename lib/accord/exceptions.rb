module Accord
  class Error < StandardError; end

  class Invalid < Error; end

  class DoesNotImplement < Invalid
    def initialize(interface)
      @interface = interface
    end
  end

  class BrokenImplementation < Invalid
    def initialize(interface, method_name)
      @interface = interface
      @method_name = method_name
    end

    def to_s
      "signature mismatch for #{@interface.inspect}##{@method_name}"
    end
  end
end
