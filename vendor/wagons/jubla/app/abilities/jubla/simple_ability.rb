module Jubla::SimpleAbility
  extend ActiveSupport::Concern

  included do
    on(Census) do
      permission(:admin).may(:manage).all
    end

    on(Event::Camp::Kind) do
      permission(:admin).may(:manage).all
    end
  end

end