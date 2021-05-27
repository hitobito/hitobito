# frozen_string_literal: true

#  Copyright (c) 2012-2021, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# == Schema Information
#
# Table name: people
#
#  id                        :integer          not null, primary key
#  additional_information    :text(16777215)
#  address                   :text(16777215)
#  authentication_token      :string(255)
#  birthday                  :date
#  company                   :boolean          default(FALSE), not null
#  company_name              :string(255)
#  contact_data_visible      :boolean          default(FALSE), not null
#  country                   :string(255)
#  current_sign_in_at        :datetime
#  current_sign_in_ip        :string(255)
#  email                     :string(255)
#  encrypted_password        :string(255)
#  event_feed_token          :string(255)
#  failed_attempts           :integer          default(0)
#  first_name                :string(255)
#  gender                    :string(1)
#  household_key             :string(255)
#  last_name                 :string(255)
#  last_sign_in_at           :datetime
#  last_sign_in_ip           :string(255)
#  locked_at                 :datetime
#  nickname                  :string(255)
#  picture                   :string(255)
#  remember_created_at       :datetime
#  reset_password_sent_at    :datetime
#  reset_password_token      :string(255)
#  salutation                :string(255)
#  show_global_label_formats :boolean          default(TRUE), not null
#  sign_in_count             :integer          default(0)
#  title                     :string(255)
#  town                      :string(255)
#  unlock_token              :string(255)
#  zip_code                  :string(255)
#  created_at                :datetime
#  updated_at                :datetime
#  creator_id                :integer
#  last_label_format_id      :integer
#  primary_group_id          :integer
#  updater_id                :integer
#
# Indexes
#
#  index_people_on_authentication_token  (authentication_token)
#  index_people_on_email                 (email) UNIQUE
#  index_people_on_event_feed_token      (event_feed_token) UNIQUE
#  index_people_on_first_name            (first_name)
#  index_people_on_household_key         (household_key)
#  index_people_on_last_name             (last_name)
#  index_people_on_reset_password_token  (reset_password_token) UNIQUE
#  index_people_on_unlock_token          (unlock_token) UNIQUE
#

class Person < ActiveRecord::Base # rubocop:disable Metrics/ClassLength

  PUBLIC_ATTRS = [ # rubocop:disable Style/MutableConstant meant to be extended in wagons
    :id, :first_name, :last_name, :nickname, :company_name, :company,
    :email, :address, :zip_code, :town, :country, :gender, :birthday,
    :picture, :primary_group_id
  ]

  INTERNAL_ATTRS = [ # rubocop:disable Style/MutableConstant meant to be extended in wagons
    :authentication_token, :contact_data_visible, :created_at, :creator_id,
    :current_sign_in_at, :current_sign_in_ip, :encrypted_password, :id,
    :last_label_format_id, :failed_attempts, :last_sign_in_at, :last_sign_in_ip,
    :locked_at, :remember_created_at, :reset_password_token, :unlock_token,
    :reset_password_sent_at, :sign_in_count, :updated_at, :updater_id,
    :show_global_label_formats, :household_key, :event_feed_token
  ]

  FILTER_ATTRS = [ # rubocop:disable Style/MutableConstant meant to be extended in wagons
    :first_name, :last_name, :nickname, :company_name, :email, :address, :zip_code, :town, :country
  ]

  GENDERS = %w(m w).freeze

  ADDRESS_ATTRS = %w(address zip_code town country).freeze

  # define devise before other modules
  devise :database_authenticatable,
         :lockable,
         :recoverable,
         :rememberable,
         :trackable,
         :timeoutable,
         :validatable

  include Groups
  include Contactable
  include DeviseOverrides
  include I18nSettable
  include I18nEnums
  include ValidatedEmail
  include PersonTags::ValidationTagged

  i18n_enum :gender, GENDERS
  i18n_setter :gender, (GENDERS + [nil])
  i18n_boolean_setter :company

  mount_uploader :picture, Person::PictureUploader

  model_stamper
  stampable stamper_class_name: :person,
            deleter: false

  has_paper_trail meta: { main_id: ->(p) { p.id }, main_type: sti_name },
                  skip: Person::INTERNAL_ATTRS + [:picture]

  acts_as_taggable

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

  has_many :event_responsibilities, class_name: 'Event',
                                    foreign_key: :contact_id,
                                    inverse_of: :contact,
                                    dependent: :nullify

  has_many :qualifications, dependent: :destroy

  has_many :subscriptions, as: :subscriber, dependent: :destroy

  has_many :relations_to_tails, class_name: 'PeopleRelation',
                                dependent: :destroy,
                                foreign_key: :head_id

  has_many :add_requests, dependent: :destroy

  has_many :notes, dependent: :destroy, as: :subject

  has_many :authored_notes, class_name: 'Note',
                            foreign_key: 'author_id',
                            dependent: :destroy

  belongs_to :primary_group, class_name: 'Group'
  belongs_to :last_label_format, class_name: 'LabelFormat'

  has_many :label_formats, dependent: :destroy
  has_many :table_displays, dependent: :destroy

  has_many :assignments, dependent: :destroy

  has_many :access_grants, class_name: 'Oauth::AccessGrant',
                           foreign_key: :resource_owner_id,
                           dependent: :delete_all

  has_many :access_tokens, class_name: 'Oauth::AccessToken',
                           foreign_key: :resource_owner_id,
                           dependent: :delete_all

  accepts_nested_attributes_for :relations_to_tails, allow_destroy: true

  attr_accessor :household_people_ids, :shared_access_token

  ### VALIDATIONS

  validates_by_schema except: [:email, :picture, :address]
  validates :email, length: { allow_nil: true, maximum: 255 } # other email validations by devise
  validates :company_name, presence: { if: :company? }
  validates :birthday,
            timeliness: { type: :date, allow_blank: true, before: Date.new(10_000, 1, 1) }
  validates :additional_information, length: { allow_nil: true, maximum: 2**16 - 1 }
  validate :assert_has_any_name
  validates :address, length: { allow_nil: true, maximum: 1024 }
  # more validations defined by devise


  ### CALLBACKS

  before_validation :override_blank_email
  before_validation :remove_blank_relations
  before_destroy :destroy_roles
  before_destroy :destroy_person_duplicates

  ### Scopes

  scope :household, -> { where.not(household_key: nil) }
  scope :with_address, -> {
    where.not(address: [nil, '']).
    where.not(zip_code: [nil, '']).
    where.not(town: [nil, '']).
    where('(last_name IS NOT NULL AND last_name <> "") OR '\
          '(company_name IS NOT NULL AND company_name <> "")')
  }
  scope :with_mobile, -> { joins(:phone_numbers).where(phone_numbers: { label: 'Mobil' }) }

  ### CLASS METHODS

  class << self
    def order_by_name
      order(Arel.sql(order_by_name_statement.join(', ')))
    end

    def order_by_name_statement
      [company_case_column(:company_name, :last_name),
       company_case_column(:last_name, :first_name),
       company_case_column(:first_name, :nickname)]
    end

    def only_public_data
      select(PUBLIC_ATTRS.collect { |a| "people.#{a}" })
    end

    def contact_data_visible
      where(contact_data_visible: true)
    end

    def preload_groups
      all.extending(Person::PreloadGroups)
    end

    def mailing_emails_for(people, labels = [])
      MailRelay::AddressList.new(people, labels).entries
    end

    def filter_attrs
      Person::FILTER_ATTRS.collect do |key, type|
        type ||= Person.columns_hash.fetch(key.to_s).type
        [key.to_sym, { label: Person.human_attribute_name(key), type: type }]
      end.to_h
    end

    def tags
      Person.tags_on(:tags).order(:name).pluck(:name)
    end

    private

    def company_case_column(if_company, otherwise)
      "CASE WHEN people.company = #{connection.quoted_true} " \
      "THEN people.#{if_company} ELSE people.#{otherwise} END"
    end
  end


  ### ATTRIBUTE INSTANCE METHODS

  def to_s(format = :default)
    if company?
      company_name
    else
      person_name(format)
    end
  end

  def person_name(format = :default)
    name = full_name(format)
    name << " / #{nickname}" if nickname? && format != :print_list
    name
  end

  def full_name(format = :default)
    case format
    when :list, :print_list then "#{last_name} #{first_name}".strip
    else "#{first_name} #{last_name}".strip
    end
  end

  def household_people
    Person.
      includes(:groups).
      where.not(id: id).
      where('id IN (?) OR (household_key IS NOT NULL AND household_key = ?)',
            household_people_ids, household_key)
  end

  def greeting_name
    first_name.presence || nickname.presence || last_name.presence || company_name
  end

  def default_group_id
    primary_group_id || groups.first.try(:id) || Group.root.id
  end

  def years
    return unless birthday?

    now = Time.zone.now.to_date
    extra = now.month > birthday.month || (now.month == birthday.month && now.day >= birthday.day)
    now.year - birthday.year - (extra ? 0 : 1)
  end

  ### AUTHENTICATION INSTANCE METHODS

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

  def save(*args) # rubocop:disable Rails/ActiveRecordOverride Overwritten to handle uniqueness validation race conditions
    super
  rescue ActiveRecord::RecordNotUnique
    errors.add(:email, :taken)
    false
  end

  def layer_group
    primary_group&.layer_group
  end

  def finance_groups
    groups_with_permission(:finance).
      flat_map(&:layer_group)
  end

  def table_display_for(parent)
    @table_display ||= TableDisplay.for(self, parent)
  end

  def oauth_applications
    application_ids = (access_grants.active + access_tokens.active).collect(&:application_id)
    Oauth::Application.where(id: application_ids)
  end

  def person_duplicates
    PersonDuplicate.where(person_1: id).or(PersonDuplicate.where(person_2: id))
  end

  def address_for_letter
    Person::Address.new(self).for_letter
  end

  private

  def override_blank_email
    self.email = nil if email.blank?
  end

  def remove_blank_relations
    relations_to_tails.each do |e|
      unless e.frozen?
        e.mark_for_destruction if e.tail_id.blank?
      end
    end
  end

  def assert_has_any_name
    if !company? && first_name.blank? && last_name.blank? && nickname.blank?
      errors.add(:base, :name_missing)
    end
  end

  # Destroy all related roles before destroying this person.
  # dependent: :destroy does not work here, because roles are paranoid.
  def destroy_roles
    roles.with_deleted.delete_all
  end

  def destroy_person_duplicates
    person_duplicates.delete_all
  end

end
