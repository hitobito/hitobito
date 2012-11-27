module Jubla::EventDecorator
  extend ActiveSupport::Concern
  
  def multiple_contact_groups?
    possible_contact_groups.count > 1 ? true : false
  end
  
end
