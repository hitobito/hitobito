module Jubla::EventsController 
  extend ActiveSupport::Concern

  included do 
    before_filter :remove_advisor, only: [:create, :update]
  end

  private
  def remove_advisor
    model_params.delete(:advisor)
  end


end
