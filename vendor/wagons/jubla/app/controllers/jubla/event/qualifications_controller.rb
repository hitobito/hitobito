module Jubla::Event::QualificationsController
  extend ActiveSupport::Concern
  
  included do
    alias_method_chain :update, :check
    alias_method_chain :destroy, :check
  end
  
  def update_with_check
    with_check { update_without_check }
  end
  
  def destroy_with_check
    with_check { destroy_without_check }
  end
  
  private
  
  def with_check
    if event.qualification_possible?
      yield
    else
      participation # load participation so it gets decorated
      render 'qualification'
    end
  end
end