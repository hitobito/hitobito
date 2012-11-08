module Jubla::EventsController 
  extend ActiveSupport::Concern

  included do 

    before_filter :remove_restricted, only: [:create, :update]

    before_render_new :default_coach

  end

  def default_coach
    if entry.class.attr_used?(:coach_id)
      entry.coach_id = parent.coach_id
    end
  end

  private
  
  def remove_restricted
    model_params.delete(:advisor)
    model_params.delete(:coach)
  end

end
