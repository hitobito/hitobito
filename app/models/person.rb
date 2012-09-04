# == Schema Information
#
# Table name: people
#
#  id                     :integer          not null, primary key
#  first_name             :string(255)
#  last_name              :string(255)
#  company_name           :string(255)
#  nickname               :string(255)
#  company                :boolean          default(FALSE), not null
#  email                  :string(255)
#  password               :string(255)
#  address                :string(1024)
#  zip_code               :integer
#  town                   :string(255)
#  country                :string(255)
#  gender                 :string(1)
#  birthday               :date
#  additional_information :text
#  contact_data_visible   :boolean          default(FALSE), not null
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  name_mother            :string(255)
#  name_father            :string(255)
#  nationality            :string(255)
#  profession             :string(255)
#  bank_account           :string(255)
#  ahv_number             :string(255)
#  ahv_number_old         :string(255)
#  j_s_number             :string(255)
#  insurance_company      :string(255)
#  insurance_number       :string(255)
#

class Person < ActiveRecord::Base
  
  PUBLIC_ATTRS = [:first_name, :last_name, :nickname, :company_name, :company, 
                  :email, :address, :zip_code, :town, :country]
  
  attr_accessible :first_name, :last_name, :company_name, :nickname, 
                  :email, :address, :zip_code, :town, :country,
                  :gender, :birthday, :additional_information
  
  include Contactable
  
  has_many :roles
  has_many :groups, through: :roles
  
  def to_s
    if company?
      company_name
    else
      name = "#{first_name} #{last_name}".strip
      name << " / #{nickname}" if nickname?
      name
    end
  end
  
  # All layers this person belongs to
  def layer_groups
    groups.collect(&:layer_group).uniq
  end
  
  # All groups where this person has the given permission(s)
  def groups_with_permission(*permissions)
    role_types = Role.types_with_permission(*permissions)
    roles.select {|r| role_types.include?(r.class) }.collect(&:group).uniq
  end
  
  # All groups where this person has a role that is visible from above 
  def groups_where_visible_from_above
    role_types = Role.visible_types
    roles.select {|r| role_types.include?(r.class) }.collect(&:group).uniq
  end
  
  # All above groups where this person is visible from
  def above_groups_visible_from
    groups_where_visible_from_above.collect(&:hierarchy).flatten.uniq
  end
  
end
