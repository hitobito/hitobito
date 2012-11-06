# Usage: restricted_role :advisor, Role::Advisor
# Adds an accessors for a restricted role to the current group.
# So it is possible to change the assigned Person like a regular group attribute.
module RestrictedRole
  extend ActiveSupport::Concern
  
  included do
    class_attribute :restricted_roles
    self.restricted_roles = {}
  end

  private

  # after the group was saved, create or destroy the restricted roles.
  def create_restricted_roles
    restricted_roles.each do |attr, type|
      role = restricted_role(attr, type)
      if role.try(:person_id) != send("#{attr}_id")
        role.destroy if role
        if id = restricted_role_id(attr, type).presence
          role = type.new
          role.person_id = id
          role.group = self
          role.save!
        end
      end
    end
  end
  
  def restricted_role(attr, type)
    @restricted_role ||= {}
    @restricted_role[attr] ||= roles.where(type: type.sti_name).first
  end
  
  def restricted_role_id(attr, type)
    @restricted_role_id ||= {}
    @restricted_role_id[attr] ||= restricted_role(attr, type).try(:person_id)
  end
  
  def set_restricted_role_id(attr, value)
    @restricted_role_id ||= {}
    @restricted_role_id[attr] = value
  end
  
  module ClassMethods
    def restricted_role(attr, type)
      after_save :create_restricted_roles
      restricted_roles[attr] = type
      role_types << type
      
      # getter for the person
      define_method attr do
        restricted_role(attr, type).try(:person)
      end
      
      # getter for the person id
      define_method "#{attr}_id" do
        restricted_role_id(attr, type)
      end
      
      # setter for the person id
      define_method "#{attr}_id=" do |value|
        set_restricted_role_id(attr, value)
      end
    end
  end

end
