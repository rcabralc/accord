module Accord
  module RO
    class << self
      def ro(root)
        flatten(root) { |item| yield(item) }.reverse.uniq.reverse
      end

    private

      def flatten(root)
        i = 0
        result = [root]
        while item = result[i]
          i += 1
          bases = yield(item)
          result.insert(i, *bases)
        end
        result
      end
    end
  end
end
