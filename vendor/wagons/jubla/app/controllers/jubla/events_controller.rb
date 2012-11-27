module Jubla::EventsController 
  extend ActiveSupport::Concern

  included do 

    before_filter :remove_restricted, only: [:create, :update]
    before_filter :application_contact, only: [:create, :update]
    before_filter :application_contacts, only: [:edit, :new]

    before_render_new :default_coach

  end

  def default_coach
    if entry.class.attr_used?(:coach_id)
      entry.coach_id = parent.coach_id
    end
  end

  def application_contact
    if entry.class.attr_used?(:application_contact_id)
      if model_params[:application_contact_id].blank? || application_contacts.count == 1
        entry.application_contact = application_contacts.first
      end
    end
  end

  def application_contacts
    if entry.class.attr_used?(:application_contact_id)
      @application_contacts = entry.possible_contact_groups
    end
  end

  private
  
  def remove_restricted
    model_params.delete(:advisor)
    model_params.delete(:coach)
  end

end
