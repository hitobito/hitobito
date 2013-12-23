# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

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
#

class Person < ActiveRecord::Base

  PUBLIC_ATTRS = [:id, :first_name, :last_name, :nickname, :company_name, :company,
                  :email, :address, :zip_code, :town, :country, :gender, :birthday,
                  :picture, :primary_group_id]

  attr_accessible :first_name, :last_name, :company_name, :nickname, :company,
                  :address, :zip_code, :town, :country,
                  :gender, :birthday, :additional_information,
                  :password, :password_confirmation, :remember_me,
                  :picture, :remove_picture

  # define devise before other modules
  devise :database_authenticatable,
         :recoverable,
         :rememberable,
         :trackable,
         :validatable

  include Groups
  include Contactable
  include DeviseOverrides

  mount_uploader :picture, PictureUploader

  model_stamper
  stampable stamper_class_name: :person,
            deleter: false


  ### ASSOCIATIONS

  has_many :roles, inverse_of: :person
  has_many :groups, through: :roles

  has_many :event_participations, class_name: 'Event::Participation',
                                  dependent: :destroy,
                                  inverse_of: :person
  has_many :event_applications, class_name: 'Event::Application',
                                through: :event_participations,
                                source: :application
  has_many :event_roles, class_name: 'Event::Role',
                         through: :event_participations,
                         source: :roles
  has_many :events, through: :event_participations

  has_many :qualifications, dependent: :destroy

  has_many :subscriptions, as: :subscriber, dependent: :destroy


  belongs_to :primary_group, class_name: 'Group'
  belongs_to :last_label_format, class_name: 'LabelFormat'


  ### VALIDATIONS

  schema_validations except: [:email, :picture, :created_at, :updated_at]
  validates :email, length: { allow_nil: true, maximum: 255 } # other email validations by devise
  validates :gender, inclusion: %w(m w), allow_blank: true
  validates :company_name, presence: { if: :company? }
  validates :birthday, timeliness: { type: :date, allow_blank: true }
  validates :additional_information, length: { allow_nil: true, maximum: 2 ** 16 - 1 }
  validate :assert_has_any_name
  # more validations defined by devise


  ### CALLBACKS
  before_validation :override_blank_email
  before_destroy :destroy_roles


  ### SCOPES

  scope :only_public_data, ->() { select(PUBLIC_ATTRS.collect { |a| "people.#{a}" }) }
  scope :contact_data_visible, where(contact_data_visible: true)
  scope :preload_groups, scoped.extending(Person::PreloadGroups)


  ### CLASS METHODS

  class << self
    def order_by_name
      order(company_case_column(:company_name, :last_name),
            company_case_column(:last_name, :first_name),
            company_case_column(:first_name, :nickname))
    end

    private

    def company_case_column(if_company, otherwise)
      "CASE WHEN people.company = #{connection.quoted_true} " +
      "THEN people.#{if_company} ELSE people.#{otherwise} END"
    end
  end


  ### INSTANCE METHODS

  def to_s(format = :default)
    if company?
      company_name
    else
      name = ''
      if format == :list
        name << "#{last_name} #{first_name}".strip
      else
        name << full_name
      end
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
    records = Role.with_deleted.
                   where(person_id: id).
                   includes(:group).
                   order('groups.name', 'roles.deleted_at')
  end

  def default_group_id
    primary_group_id || groups.first.try(:id) || Group.root.id
  end

  # Is this person allowed to login?
  def login?
    persisted?
  end

  # Does this person have a password set?
  def password?
    encrypted_password?
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

  private

  def override_blank_email
    self.email = nil if email.blank?
  end

  def assert_has_any_name
    if !company? && first_name.blank? && last_name.blank? && nickname.blank?
      errors.add(:base, 'Bitte geben Sie einen Namen ein')
    end
  end

  # Destroy all related roles before destroying this person.
  # dependent: :destroy does not work here, because roles are paranoid.
  def destroy_roles
    roles.with_deleted.delete_all
  end

end
