require 'accord/interface'

module Accord
  module Interfaces
    # A hash-like container for tags.
    Accord::Interface(self, :Tags) do
      # Return the value associated with a tag.
      # @param tag [String, Symbol] the tag.
      # @return [Object] the value associated with the tag.
      responds_to :[], params: :tag

      # Associates a tag with a value.
      # @param tag [String, Symbol] the tag.
      # @param value [Object] any value.
      # @return [void]
      responds_to :[]=, params: [:tag, :value]

      # Return the value associated with `tags`.
      # @param tag [String, Symbol] the tag to look for.
      # @param default [Object] any default value that should be returned when
      #   the tag is not found.
      # @raise ArgumentError if the default value is not provided and the tag
      #   is not found.
      responds_to :fetch do
        param :tag
        param default: Accord::UNSPECIFIED
      end
    end

    # Objects that have a name and tags.
    Accord::Interface(self, :Element) do
      # The object name
      # @return [String] the name of the object.
      responds_to :name

      # Element tags.
      # @return [Tags] tags associated with this element.
      responds_to :tags
    end

    Accord::Interface(self, :SignatureInfo) do
      # Arguments
      # @return [<Hash>] sequence of hashes with a `:name` key which is the
      #   proposed name of the argument and an optional `:default` key which is
      #   the default value of the argument, if any.  The arguments are listed
      #   in the order they are expected by implementations.
      responds_to :arguments

      # Variable arguments name
      # @return [Symbol] the name of the splat argument or nil if none is
      #   expected.
      responds_to :splat

      # Block argument name
      # @return [Symbol] the name of the block argument or nil if none is
      #   expected.
      responds_to :block
    end

    Accord::Interface(self, :Method) do
      extends Element

      # The interface on which this method is defined.
      # @return [Interface]
      responds_to :interface

      # Signature information.
      # @return [SignatureInfo] signature info of the method.
      responds_to :signature_info
    end

    Accord::Interface(self, :Specification) do
      # @return [<Specification>] the list of specifications from which this
      #   specification is directly derived.
      responds_to :bases

      # @param bases [<Specification>] a list of specifications from which this
      #   specification is directly derived.
      # @return [void]
      responds_to :bases=, params: :bases

      # @return [<Specification>] the list of specifications from which this
      #   specification is derived, including self, from most specific to least
      #   specific (similar to ancestors of a Ruby module).
      responds_to :ancestors

      # Test whether this specification extends another.
      #
      # The specification extends other if it has other as a base or if one of
      # its bases extends other.
      #
      # A specification always extends itself.
      #
      # @param other [Specification] the other specification.
      # @return [Boolean] if this specification extends other.
      responds_to :extends?, params: :other
    end

    Accord::Interface(self, :Interface) do
      extends Element, Specification

      # Interface resolution order
      # @return [<Interface>] the sequence of ancestors which are interfaces.
      responds_to :iro

      # Interface methods names.
      # @return [<Symbol>] the sequence of method names of the interface in the
      #   order they were defined.
      # @note All ancestors are verified.
      responds_to :method_names

      # All interface method names.
      # @return [<Symbol>] the sequence of method names of the interface in the
      #   order they were first defined.
      # @note Return only methods defined in the interface.
      responds_to :own_method_names

      # Get the method object of a name.
      # @param name [String, Symbol] the name of the method.
      # @return [Method] the method or nil if the method doesn't exists.
      # @note All ancestors are verified.
      responds_to :[], params: :name

      # Test whether the name is defined in the interface.
      # @param name [String, Symbol] the name of the method.
      # @return [Boolean] true if the method is defined.
      # @note All ancestors are verified.
      responds_to :defined?, params: [:name, { all: true }]

      # Test whether the name is defined in the interface.
      # @param name [String, Symbol] the name of the method.
      # @note All ancestors are verified.
      # @return [Boolean] true if the method is defined in the interface.
      responds_to :owns?, params: [:name, { all: true }]

      # Iterate over the methods defined by the interface in the order they
      # where defined.
      # @yield [name, Method] the name of the method as a symbol and the method
      #   object.
      # @return [void]
      responds_to :each

      # Validate invariants.
      # @param object [Object] the object to validate.
      # @param errors [<Object>] any container where the errors will be pushed
      #   to, defaults to nil (no container to push errors to).
      # @return [Boolean] true if no invariant was violated, false otherwise.
      # @note All invariants of all ancestors are checked against the object.
      responds_to :assert_invariants?, params: [:object, { errors: nil }]

      # Validate invariants.
      # @param (see #assert_invariants?)
      # @raise Exception if any invariant has been violated, but pushes all
      #   errors to the errors container before raising.
      # @note All invariants of all ancestors are checked against the object.
      responds_to :assert_invariants, params: [:object, { errors: nil }]

      # Test if the object claims to provide this interface.
      #
      # This is done by checking if this interface or any of its extensions was
      # previously declared as directly provided by the object or as
      # implemented by its class.  No further tests are done.
      #
      # @param object [Object] the object to test.
      # @return [Boolean] true if the interface is provided by the object.
      responds_to :provided_by?, params: :object

      # Test if the interface is claimed to be implemented by the given
      # factory.

      # This is done by checking if this interface or any of its extensions was
      # previously declared as implemented by the factory.  No further tests
      # are done.
      #
      # @param factory [Class, Module, Proc] the factory to test.
      # @return [Boolean] true if the interface is implemented by the factory.
      responds_to :implemented_by?, params: :factory
    end

    Accord::Interface(self, :Declaration) do
      extends Specification

      # Tests whether the given interface is in the specification.
      # @param interface [Interface] the interface.
      # @return [Boolean] true if the given interface is one of the interfaces
      #   in the specification or false otherwise.
      responds_to :extends?, params: :interface

      # Create a new declaration with the interfaces from self and other.
      # @param other [Specification] the other specification.
      # @return [Declaration] a new declaration.
      responds_to :+, params: :other

      # Create a new declaration with interfaces that don't extend any of the
      # other.
      # @param other [Specification] the other specification.
      # @return [Declaration] a new declaration.
      responds_to :-, params: :other
    end

    Accord::Interface(self, :InterfaceDeclarations) do
      responds_to :provided_by,          params: :object
      responds_to :directly_provided_by, params: :object
      responds_to :implemented_by,       params: :factory
      responds_to :implements,           params: [:factory, :"*interfaces"]
      responds_to :implements_only,      params: [:factory, :"*interfaces"]
      responds_to :directly_provides,    params: [:object,  :"*interfaces"]
      responds_to :also_provides,        params: [:object,  :"*interfaces"]
      responds_to :no_longer_provides,   params: [:object,  :interface]
    end

    Accord::Interface(self, :AdapterRegistry) do
      responds_to :register, params: [:required, :provided, :name, :value]
    end

    Accord::Interface(self, :InterfaceBody) do
      # Declares that an object providing the interface should respond to a
      # method.
      #
      # @param message_name [Symbol] the name of the method.
      # @param options [Hash] options hash, defaults to an empty hash.
      # @yield
      # @raise ArgumentError if a `:params` option is passed and also a block.
      #
      # == Detailed description
      #
      # This method can be used in three ways: without options or block, with
      # the `:params` option or with a block which takes no parameters.
      #
      # Usage without any option and without block is straightforward:
      #
      #   responds_to :method
      #
      # This declares that objects providing this interface should respond to
      # `.method`.
      #
      # Examples for the `:params` option:
      #
      #   responds_to :method, params: :single_argument
      #   responds_to :method, params: [:single_argument]
      #   responds_to :method, params: { single_with_default: default }
      #   responds_to :method, params: [{ single_with_default: default }]
      #   responds_to :method, params: [:a1, { a2: default }, :"*args", :"&blk"]
      #
      # Which would be fulfilled in a real implementation with:
      #
      #   def method(single_argument); end
      #   def method(single_argument=default); end
      #   def method(a1, a2=default, *args, &blk); end
      #
      # Using a block the same examples would be declared as the following:
      #
      #   responds_to :method do
      #     param :single_argument
      #   end
      #
      #   responds_to :method do
      #     param single_argument: default
      #   end
      #
      #   responds_to :method do
      #     param :a1
      #     param a2: default
      #     splat :args
      #     block :blk
      #   end
      #
      # In all cases, the implementation should respect the order the arguments
      # where declared, but doesn't need to respect the names of the arguments.
      # The names are described here for clarification, documentation and
      # design intent purposes.
      #
      # @note When a default value exists but is not specified (or is unknown,
      #   or is irrelevant), use `Accord::UNSPECIFIED`.  This also can be used
      #   when the argument can be optionally given or not.  Implementations
      #   may not rely on this value, though.
      responds_to :responds_to do
        param :message_name
        param options: {}
        block :block
      end

      # Declare an invariant.
      #
      # @param name [Symbol] the name of the invariant.
      # @yields [object, error] the object on which the invariant must hold and
      #   an errors container (which responds to `<<` and `push`).
      #
      # == Example
      #
      # Let's say that a event should not start after end:
      #
      #   Account = Accord::Interface(:Event) do
      #     respond_to :start_date
      #     respond_to :end_date
      #     invariant :event_consistency do |object, errors|
      #       next unless start = object.start_date
      #       next unless end   = object.end_date
      #       errors.push("cannot start after end") unless start <= end
      #     end
      #   end
      #
      # Errors don't need to be a string.  Actually, they can be any object.
      #
      #   Account = Accord::Interface(:Event) do
      #     respond_to :start_date
      #     respond_to :end_date
      #     invariant :event_consistency do |object, errors|
      #       next unless start = object.start_date
      #       next unless end   = object.end_date
      #       errors << CausalityViolation.new(start, end) unless start <= end
      #     end
      #   end
      #
      # In the examples above, every time an object providing `Event` which
      # starts after its end is checked, the invariant is considered violated,
      # since an error is pushed into the `errors` container.  If no error is
      # pushed, the invariant succeeds.
      responds_to :invariant, params: :name

      # Declare that this interface extends another or various.
      # @param interfaces [Interface] one or more interfaces to extend.  They
      # are added in the reversed order they are given, so the last one listed
      # is the most specific (that is, will appear first in the bases array and
      # its ancestors will also appear first in the ancestors array).  Bases
      # already extended are ignored.
      responds_to(:extends) { splat :interfaces }
    end
  end
end
