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
#  picture                :string(255)
#  last_label_format_id   :integer
#  creator_id             :integer
#  updater_id             :integer
#  primary_group_id       :integer
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

  PUBLIC_ATTRS = [:id, :first_name, :last_name, :nickname, :company_name, :company,
                  :email, :address, :zip_code, :town, :country, :birthday, :picture, :primary_group_id]

  attr_accessible :first_name, :last_name, :company_name, :nickname, :company,
                  :email, :address, :zip_code, :town, :country,
                  :gender, :birthday, :additional_information,
                  :password, :password_confirmation, :remember_me,
                  :picture, :remove_picture

  include Groups
  include Contactable

  devise :database_authenticatable,
         :recoverable,
         :rememberable,
         :trackable,
         :validatable

  mount_uploader :picture, PictureUploader

  model_stamper
  stampable stamper_class_name: :person,
            deleter: false


  ### ASSOCIATIONS

  has_many :roles, inverse_of: :person
  has_many :groups, through: :roles

  has_many :event_participations, class_name: 'Event::Participation', dependent: :destroy, inverse_of: :person
  has_many :event_applications, class_name: 'Event::Application', through: :event_participations, source: :application
  has_many :event_roles, class_name: 'Event::Role', through: :event_participations, source: :roles
  has_many :events, through: :event_participations

  has_many :qualifications, dependent: :destroy

  has_many :subscriptions, as: :subscriber, dependent: :destroy


  belongs_to :primary_group, class_name: 'Group'
  belongs_to :last_label_format, class_name: 'LabelFormat'


  ### VALIDATIONS

  schema_validations except: [:picture, :created_at, :updated_at]
  validates :gender, inclusion: %w(m w), allow_blank: true
  validates :company_name, presence: { if: :company? }
  validate :assert_has_any_name
  # more validations defined by devise


  ### CALLBACKS
  before_validation :override_blank_email
  before_destroy :destroy_roles


  ### SCOPES

  scope :only_public_data, select(PUBLIC_ATTRS.collect {|a| "people.#{a}" })
  scope :contact_data_visible, where(contact_data_visible: true)
  scope :preload_groups, scoped.extending(Person::PreloadGroups)
  scope :order_by_name, order("CASE WHEN people.company = #{ActiveRecord::Base.connection.quoted_true}" +
                              " THEN people.company_name ELSE people.last_name END",
                              "CASE WHEN people.company = #{ActiveRecord::Base.connection.quoted_true}" +
                              " THEN people.last_name ELSE people.first_name END",
                              "CASE WHEN people.company = #{ActiveRecord::Base.connection.quoted_true}" +
                              " THEN people.first_name ELSE people.nickname END")


  ### INDEXED FIELDS

  define_partial_index do
    indexes first_name, last_name, company_name, nickname, company, email, sortable: true
    indexes address, zip_code, town, country, birthday, additional_information

    indexes phone_numbers.number, as: :phone_number
    indexes social_accounts.name, as: :social_account
  end


  ### CLASS METHODS


  ### INSTANCE METHODS

  def to_s
    if company?
      company_name
    else
      name = full_name
      name << " / #{nickname}" if nickname?
      name
    end
  end

  def full_name
    "#{first_name} #{last_name}".strip
  end

  def greeting_name
    first_name.presence || nickname.presence || last_name.presence || company_name
  end

  def male?
    gender == 'm'
  end

  def female?
    gender == 'w'
  end

  def upcoming_events
    events.upcoming.merge(Event::Participation.active).uniq
  end

  def pending_applications
    event_applications.merge(Event::Participation.pending)
  end

  # All time roles of this person, including deleted.
  def all_roles
    records = Role.with_deleted.where(person_id: id).includes(:group).order('groups.name', 'roles.deleted_at')
  end

  def default_group_id
    primary_group_id || groups.first.try(:id) || Group.root.id
  end

  # Is this person allowed to login?
  def login?
    persisted?
  end

  # Is this person root?
  def root?
    email == Settings.root_email
  end

  # Overwrite to handle uniquness validation race conditions
  def save(*args)
    super
  rescue ActiveRecord::RecordNotUnique => e
    errors.add(:email, :taken)
    false
  end

  def send_reset_password_instructions # from lib/devise/models/recoverable.rb
    persisted? && super
  end

  def clear_reset_password_token!
    clear_reset_password_token && save(validate: false)
  end

  # Owner: Devise::Models::DatabaseAuthenticatable
  # We override this to allow users updating passwords when no password has been set
  def update_with_password(params, *options)
    current_password = params.delete(:current_password)

    if params[:password].blank?
      params.delete(:password)
      params.delete(:password_confirmation) if params[:password_confirmation].blank?
    end

    result = if encrypted_password.nil? || valid_password?(current_password)
               update_attributes(params, *options)
             else
               self.assign_attributes(params, *options)
               self.valid?
               self.errors.add(:current_password, current_password.blank? ? :blank : :invalid)
               false
             end

    clean_up_passwords
    result
  end

  public :generate_reset_password_token!

  private

  def email_required?
    false
  end

  # Checks whether a password is needed or not. For validations only.
  # Passwords are required if the password or confirmation are being set somewhere.
  def password_required?
    !password.nil? || !password_confirmation.nil?
  end

  def override_blank_email
    self.email = nil if email.blank?
  end

  def assert_has_any_name
    if !company? && first_name.blank? && last_name.blank? && nickname.blank?
      errors.add(:base, "Bitte geben Sie einen Namen ein")
    end
  end

  # Destroy all related roles before destroying this person.
  # dependent: :destroy does not work here, because roles are paranoid.
  def destroy_roles
    roles.with_deleted.delete_all
  end

end
