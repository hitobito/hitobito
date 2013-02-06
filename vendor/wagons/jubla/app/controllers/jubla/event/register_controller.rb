module Jubla::Event::RegisterController
    
  extend ActiveSupport::Concern
    
  included do
    alias_method_chain :create_person, :role
  end
    
  def create_person_with_role
    if create_person_without_role
      role = Jubla::Role::External.new
      role.group = group
      role.person = person
      role.save!
      person.roles << role
      true
    end
  end
end