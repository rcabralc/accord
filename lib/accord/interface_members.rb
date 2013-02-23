module Accord
  class InterfaceMembers
    def initialize(interface)
      @interface = interface
      @hash = {}
      @order = []
    end

    def add(member_name, member)
      member_name = member_name.to_sym
      @order << member_name unless @order.include?(member_name)
      @hash[member_name] = member
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
  end
end
