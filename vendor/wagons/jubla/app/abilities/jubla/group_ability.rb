module Jubla::GroupAbility
  extend ActiveSupport::Concern

  included do
    on(Group) do
      permission(:layer_full).may(:index_event_course_conditions).in_same_layer_or_below
    end
  end

end