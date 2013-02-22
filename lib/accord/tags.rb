module Accord
  class Tags
    def initialize
      @hash = {}
    end

    def []=(tag, value)
      @hash[tag.to_sym] = value
    end

    def [](tag)
      @hash[tag.to_sym]
    end

    def fetch(tag, default=Tags.marker)
      return @hash[tag] if @hash.has_key?(tag)
      return default unless default.equal?(self.class.marker)
      raise ArgumentError, "tag #{tag.inspect} not found."
    end

    def self.marker
      @marker ||= Object.new
    end
  end
end
