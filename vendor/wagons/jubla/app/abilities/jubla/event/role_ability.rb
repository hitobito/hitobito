module Jubla::Event::RoleAbility
  extend ActiveSupport::Concern

  include Jubla::EventConstraints

  included do
    on(Event::Role) do
      general.not_closed_or_admin
    end
  end

end