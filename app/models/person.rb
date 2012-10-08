# encoding: utf-8
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
#  encrypted_password     :string(255)
#  reset_password_token   :string(255)
#  reset_password_sent_at :datetime
#  remember_created_at    :datetime
#  sign_in_count          :integer          default(0)
#  current_sign_in_at     :datetime
#  last_sign_in_at        :datetime
#  current_sign_in_ip     :string(255)
#  last_sign_in_ip        :string(255)
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
  
  # Setup accessible (or protected) attributes for your model
  PUBLIC_ATTRS = [:id, :first_name, :last_name, :nickname, :company_name, :company, 
                  :email, :address, :zip_code, :town, :country, :birthday]
  
  attr_accessible :first_name, :last_name, :company_name, :nickname, :company,
                  :email, :address, :zip_code, :town, :country,
                  :gender, :birthday, :additional_information,
                  :password, :password_confirmation, :remember_me
  
  include Roles
  include Contactable
  
  devise :database_authenticatable,
         :recoverable, :rememberable, :trackable, :validatable
  
  ### ASSOCIATIONS
  
  has_many :roles, dependent: :destroy, inverse_of: :person
  has_many :groups, through: :roles
  
  has_many :event_participations, class_name: 'Event::Participation', dependent: :destroy, inverse_of: :person
  has_many :event_applications, class_name: 'Event::Application', through: :event_participations, source: :application
  has_many :event_roles, class_name: 'Event::Role', through: :event_participations, source: :roles
  
  
  ### VALIDATIONS
  
  validates :email, uniqueness: true, allow_nil: true
  validates :gender, inclusion: %w(m w), allow_blank: true
  validate :assert_has_any_name
 
 
  ### SCOPES

  scope :only_public_data, select(PUBLIC_ATTRS.collect {|a| "people.#{a}" })
  scope :contact_data_visible, where(:contact_data_visible => true)
  scope :preload_groups, scoped.extending(Person::PreloadGroups)
  scope :order_by_name, order('people.last_name, people.first_name')
  scope :order_by_company, order('people.company_name, people.last_name, people.first_name')
  
  
  ### CLASS METHODS
  
  class << self
    # Order people by the order participation types are listed in their event types.
    def order_by_participation(event_type)
      statement = "CASE event_role.type "
      event_type.role_types.each_with_index do |t, i|
        statement << "WHEN '#{t.sti_name}' THEN #{i} "
      end
      statement << "END"
      joins(:event_roles).order(statement)
    end
  end

  ### INSTANCE METHODS
  
  def to_s
    if company?
      company_name
    else
      name = "#{first_name} #{last_name}".strip
      name << " / #{nickname}" if nickname?
      name
    end
  end

  def all_roles
    records = Role.unscoped.where(person_id: id).order('deleted_at').includes(:group)
  end
  
  def login?
    permission?(:login)
  end

  
  def send_reset_password_instructions # from lib/devise/models/recoverable.rb
    login? && super
  end

  private
  def email_required?
    login?
  end
  
  def password_required?
    email_required? && password.present? && password_confirmation.present?
  end
  
  def assert_has_any_name
    if first_name.blank? && last_name.blank? && ((company? && company_name.blank?) || (!company? && nickname.blank?))
      errors.add(:base, "Bitte geben Sie einen Namen für diese Person ein")
    end
  end
  
end
