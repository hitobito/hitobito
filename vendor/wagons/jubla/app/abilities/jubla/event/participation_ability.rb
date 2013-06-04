module Jubla::Event::ParticipationAbility
  extend ActiveSupport::Concern
  include Jubla::EventAbility

  private

  def may_run_action_if_closed?
    may_modify_closed?(:create, :update, :destroy)
  end

end