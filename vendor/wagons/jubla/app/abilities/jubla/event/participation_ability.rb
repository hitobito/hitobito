module Jubla::Event::ParticipationAbility
  extend ActiveSupport::Concern

  include Jubla::EventConstraints

  included do
    on(Event::Participation) do
      general(:update, :destroy).not_closed_or_admin
      general(:create).at_least_one_group_not_deleted_and_not_closed_or_admin
    end
  end

end