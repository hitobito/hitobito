module Jubla::EventAbility
  extend ActiveSupport::Concern

  include Jubla::EventConstraints

  included do
    on(Event) do
      general(:update, :destroy, :application_market, :qualify).at_least_one_group_not_deleted_and_not_closed_or_admin
    end
  end

end
