Accord - object interfaces and adaptation for Ruby
==================================================

Accord is a gem providing basic object interface and adaptation support for
Ruby.  An interface represents a protocol or contract (an API), and this gem
allows you to label your objects/classes/modules as being compliant with a
given API by declaring them as implementing/providing interfaces.  Thus, one
would call this an implementation of `Design by Contract
<http://en.wikipedia.org/wiki/Design_by_contract>`_ in Ruby.

Object adaptation is also supported.  Given an object which claims to provide
some API, and in a specific point of the code another API is needed, Accord
will allow adapting from the object API to the desired one (provided that an
*adapter* which can adapt the APIs is known by Accord).

This gem was largely inspired by the Python package ``zope.interface``,
maintained by the `Zope Toolkit Project <http://docs.zope.org/zopetoolkit/>`_.
``zope.interface`` source `can be found here
<https://github.com/zopefoundation/zope.interface>`_.

Disclaimer: this is not used in any real world project yet. The API is still
changing (and will, while this gem is not in the 1.0 version).  Not ready for
prime time.


Basic usage
-----------

Declare some interfaces::

  Labelled = Accord::Interface(:Labelled) do
    responds_to :label
  end
  PersonAPI = Accord::Interface(:PersonAPI)

Implement them::

  class Person
    attr_reader :name
    def initialize(name)
      @name = name
    end
  end

  class PersonLabel
    def initialize(person)
      @person = person
    end
    def label
      @person.name
    end
  end

Declare that your classes are implementations of the interfaces::

  Accord::Declarations.implements(Person, PersonAPI)
  Accord::Declarations.implements(PersonLabel, Labelled)

Tell Accord that people can have labels (that is, they can be adapted to
`Labelled`)::

  Accord.default_adapter_registry.register([PersonAPI], Labelled) do |person|
    PersonLabel.new(person)
  end

Now, in a piece of code which needs a label::

  def show(object)
    Labelled.adapt!(object).label
  end

When a person is given to `#show`, its name will be used to provide a label::

  person = Person.new('John')
  show(person) #=> 'John'

By registering more adapters, `#show` can be reused to show the labels of
other types of objects, without changing its source.  `#show` doesn't rely on
receiving a person, but depends only on an interface.  Also, everything could
have been added in the application after the `Person` class (as if that class
were legacy code), without modifying its source.  Or `Person` could be a class
in a third party library.


License
-------

This gem is MIT-licensed.  See LICENSE.txt in the root of this repository.
