require 'accord/specification'

module Accord
  module Declarations
    class Declaration < Specification
      def extends?(interface)
        super(interface) && interfaces.include?(interface)
      end

      def + other
        Declaration.new(interfaces + other.interfaces)
      end

      def - other
        Declaration.new(interfaces.select { |i|
          !other.interfaces.any? { |j| i.extends?(j) }
        })
      end
    end

    class Implements < Declaration
      attr_reader :name

      def initialize(inherit)
        @inherit = inherit
        set_name(inherit)
        @declared = []
        super(bases_from_inherit)
      end

      def declare(*interfaces)
        @declared.concat(normalized(interfaces)).uniq!
        new_bases = @declared.dup
        bases_from_inherit.each do |base|
          new_bases << base if !@declared.include?(base)
        end
        self.bases = new_bases
      end

      def declare_only(*interfaces)
        @declared = []
        self.inherit = nil
        declare(*interfaces)
      end

      def inspect
        "#<Implemented by #{name}>"
      end

    private

      attr_accessor :inherit

      def set_name(inherit)
        if inherit.respond_to?(:name)
          if inherit.name.to_s != ''
            @name = inherit.name
          else
            @name = inherit.inspect
          end
        else
          @name = inherit.inspect
        end
      end

      def bases_from_inherit
        if inherit.is_a?(Module)
          ancestors = inherit.ancestors
          ancestors.delete(inherit)
          ancestors.map { |ancestor| Declarations.implemented_by(ancestor) }
        else
          []
        end
      end

      def normalized(args)
        enum_for(:normalize, args).to_a
      end

      def normalize(args, &block)
        if args.is_a?(InterfaceClass) || args.is_a?(Implements)
          block.call(args)
        else
          args.each do |arg|
            normalize(arg, &block)
          end
        end
      end
    end

    class << self
      def provided_by(object)
        implemented_by(object.class) + directly_provided_by(object)
      end

      def directly_provided_by(object)
        object.instance_eval do
          @_accord_provides_ ||= Declaration.new
        end
      end

      def implemented_by(factory)
        factory.instance_eval do
          @_accord_implements_ ||= Implements.new(self)
        end
      end

      def implements(cls, *interfaces)
        implemented_by(cls).declare(*interfaces)
      end

      def implements_only(cls, *interfaces)
        implemented_by(cls).declare_only(*interfaces)
      end

      def directly_provides(object, *interfaces)
        object.instance_eval do
          @_accord_provides_ = Declaration.new(interfaces)
        end
      end

      def also_provides(object, *interfaces)
        directly_provides(object, directly_provided_by(object), *interfaces)
      end

      def no_longer_provides(object, interface)
        directly_provides(object, directly_provided_by(object) - interface)
      end
    end
  end
end
