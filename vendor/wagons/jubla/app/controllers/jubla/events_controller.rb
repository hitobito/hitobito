module Jubla::EventsController 
  extend ActiveSupport::Concern

  included do 
    before_filter :remove_restricted, only: [:create, :update]

    before_render_new :default_coach

    before_render_form :application_contacts
    before_render_form :load_conditions

    before_save :set_application_contact
  end


  private
  
  def default_coach
    if entry.class.attr_used?(:coach_id)
      entry.coach_id = parent.coach_id
    end
  end

  def set_application_contact
    if entry.class.attr_used?(:application_contact_id)
      if model_params[:application_contact_id].blank? || application_contacts.count == 1
        entry.application_contact = application_contacts.first
      end
    end
  end

  def application_contacts
    if entry.class.attr_used?(:application_contact_id)
      @application_contacts ||= entry.possible_contact_groups
    end
  end

  def load_conditions
    if entry.kind_of?(Event::Course) 
      @conditions = Event::Course::Condition.where(:group_id => entry.group_ids).order(:label)
    end
  end

  def remove_restricted
    model_params.delete(:advisor)
    model_params.delete(:coach)
  end

end
