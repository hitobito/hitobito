require 'awesome_nested_set/move'

module CollectiveIdea #:nodoc:
  module Acts #:nodoc:
    module NestedSet #:nodoc:
      class Move

        private

        def conditions_with_timestamper(a, b, c, d)
          conditions_without_timestamper(a, b, c, d).tap do |conditions|
            if @instance.respond_to?(:no_touch_on_move) && @instance.no_touch_on_move
              conditions.first.gsub!(', updated_at = :timestamp', '')
            end
          end
        end
        alias_method_chain :conditions, :timestamper

      end
    end
  end
end
