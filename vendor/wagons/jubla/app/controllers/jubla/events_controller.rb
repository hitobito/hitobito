module Jubla::EventsController 
  extend ActiveSupport::Concern

  included do 

    before_filter :remove_advisor, only: [:create, :update]
    before_filter :remove_coach, only: [:create, :update]

    def new
      if entry.class.attr_used?(:coach_id)
        entry.coach_id = parent.coach.try(:id)
      end
      super
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
