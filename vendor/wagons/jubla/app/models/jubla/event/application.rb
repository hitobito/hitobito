module Jubla::Event::Application
  extend ActiveSupport::Concern
  
  
  included do
    alias_method_chain :contact, :group_type
  end
  
  def contact_with_group_type
    group = priority_1.group
    if type = group.class.contact_group_type
      group.children.where(type: type.sti_name).first
    else
      contact_without_group_type
    end
  end
  
end