module Jubla::EventAbility
  extend ActiveSupport::Concern

  included do
    alias_method_chain :general_conditions, :jubla
  end

  def general_conditions_with_jubla
    general_conditions_without_jubla &&
    may_run_action_if_closed?
  end

  private

  def may_run_action_if_closed?
    may_modify_closed?(:application_market, :update, :destroy, :qualify)
  end

  def may_modify_closed?(*actions)
    case action
    when *actions then user_context.admin || !is_closed_course?
    else true
    end
  end

  def is_closed_course?
    event.kind_of?(Event::Course) && event.closed?
  end

end
