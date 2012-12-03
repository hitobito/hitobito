module Jubla::Event::Application
  extend ActiveSupport::Concern
  
  
  included do
    alias_method_chain :contact, :group_type
  end
  
  def contact_with_group_type
    if event.application_contact.present?
      event.application_contact
    else
      contact_without_group_type
    end
  end
  
end
