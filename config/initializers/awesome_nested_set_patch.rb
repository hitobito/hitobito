require 'awesome_nested_set/move'

module CollectiveIdea #:nodoc:
  module Acts #:nodoc:
    module NestedSet #:nodoc:
      class Move

        module Timestamp
          def conditions(a, b, c, d)
            super(a, b, c, d).tap do |conditions|
              if @instance.respond_to?(:no_touch_on_move) && @instance.no_touch_on_move
                conditions.first.gsub!(', updated_at = :timestamp', '')
              end
            end
          end
        end

        private

        prepend CollectiveIdea::Acts::NestedSet::Move::Timestamp

      end
    end
  end
end
