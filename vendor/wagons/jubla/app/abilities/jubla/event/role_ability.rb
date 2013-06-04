module Jubla::Event::RoleAbility
  extend ActiveSupport::Concern
  include Jubla::EventAbility

  private

  def may_run_action_if_closed?
    may_modify_closed?(:manage)
  end

end