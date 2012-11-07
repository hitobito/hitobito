module Jubla::EventsController 
  extend ActiveSupport::Concern

  included do 

    before_filter :remove_advisor, only: [:create, :update]
    before_filter :remove_coach, only: [:create, :update]

    before_render_form :default_coach, only: :new

  end

  def default_coach
    if entry.class.attr_used?(:coach_id)
      entry.coach_id = parent.coach_id
    end
  end

  private
  def remove_advisor
    model_params.delete(:advisor)
  end

  def remove_coach
    model_params.delete(:coach)
  end

end
