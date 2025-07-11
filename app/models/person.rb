# frozen_string_literal: true

#  Copyright (c) 2012-2024, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# == Schema Information
#
# Table name: people
#
#  id                                   :integer          not null, primary key
#  additional_information               :text
#  address_care_of                      :string
#  authentication_token                 :string
#  birthday                             :date
#  blocked_at                           :datetime
#  company                              :boolean          default(FALSE), not null
#  company_name                         :string
#  confirmation_sent_at                 :datetime
#  confirmation_token                   :string
#  confirmed_at                         :datetime
#  contact_data_visible                 :boolean          default(FALSE), not null
#  country                              :string
#  current_sign_in_at                   :datetime
#  current_sign_in_ip                   :string
#  email                                :string
#  encrypted_password                   :string
#  encrypted_two_fa_secret              :text
#  event_feed_token                     :string
#  failed_attempts                      :integer          default(0)
#  family_key                           :string
#  first_name                           :string
#  gender                               :string(1)
#  household_key                        :string
#  housenumber                          :string(20)
#  inactivity_block_warning_sent_at     :datetime
#  language                             :string           default("de"), not null
#  last_name                            :string
#  last_sign_in_at                      :datetime
#  last_sign_in_ip                      :string
#  locked_at                            :datetime
#  membership_verify_token              :string
#  minimized_at                         :datetime
#  nickname                             :string
#  postbox                              :string
#  privacy_policy_accepted_at           :datetime
#  remember_created_at                  :datetime
#  reset_password_sent_at               :datetime
#  reset_password_sent_to               :string
#  reset_password_token                 :string
#  self_registration_reason_custom_text :string(100)
#  show_global_label_formats            :boolean          default(TRUE), not null
#  sign_in_count                        :integer          default(0)
#  street                               :string
#  town                                 :string
#  two_factor_authentication            :integer
#  unconfirmed_email                    :string
#  unlock_token                         :string
#  zip_code                             :string
#  created_at                           :datetime
#  updated_at                           :datetime
#  creator_id                           :integer
#  last_label_format_id                 :integer
#  primary_group_id                     :integer
#  self_registration_reason_id          :bigint
#  updater_id                           :integer
#
# Indexes
#
#  index_people_on_authentication_token         (authentication_token)
#  index_people_on_confirmation_token           (confirmation_token) UNIQUE
#  index_people_on_email                        (email) UNIQUE
#  index_people_on_event_feed_token             (event_feed_token) UNIQUE
#  index_people_on_first_name                   (first_name)
#  index_people_on_household_key                (household_key)
#  index_people_on_last_name                    (last_name)
#  index_people_on_reset_password_token         (reset_password_token) UNIQUE
#  index_people_on_self_registration_reason_id  (self_registration_reason_id)
#  index_people_on_unlock_token                 (unlock_token) UNIQUE
#  people_search_column_gin_idx                 (search_column) USING gin
#
# Foreign Keys
#
#  fk_rails_...  (self_registration_reason_id => self_registration_reasons.id)
#

class Person < ActiveRecord::Base # rubocop:disable Metrics/ClassLength
  PUBLIC_ATTRS = [ # rubocop:disable Style/MutableConstant meant to be extended in wagons
    :id, :first_name, :last_name, :nickname, :company_name, :company,
    :email, :address_care_of, :street, :housenumber, :postbox, :zip_code, :town, :country,
    :gender, :birthday, :primary_group_id
  ]

  INTERNAL_ATTRS = [ # rubocop:disable Style/MutableConstant meant to be extended in wagons
    :authentication_token, :contact_data_visible, :created_at, :creator_id,
    :current_sign_in_at, :current_sign_in_ip, :encrypted_password, :id,
    :last_label_format_id, :failed_attempts, :last_sign_in_at, :last_sign_in_ip,
    :locked_at, :remember_created_at, :reset_password_token, :unlock_token,
    :reset_password_sent_at, :reset_password_sent_to, :sign_in_count, :updated_at, :updater_id,
    :show_global_label_formats, :household_key, :event_feed_token, :family_key,
    :two_factor_authentication, :encrypted_two_fa_secret,
    :confirmation_token, :confirmed_at, :confirmation_sent_at, :unconfirmed_email,
    :self_registration_reason_custom_text,
    :self_registration_reason_id,
    :privacy_policy_accepted_at,
    :blocked_at,
    :membership_verify_token,
    :inactivity_block_warning_sent_at,
    :minimized_at
  ]

  MERGABLE_ATTRS = PUBLIC_ATTRS - [:id, :primary_group_id, :picture]

  FILTER_ATTRS = [ # rubocop:disable Style/MutableConstant meant to be extended in wagons
    :first_name, :last_name, :nickname, :company_name, :email, :address_care_of, :street,
    :housenumber, :postbox, :zip_code, :town, [:country, :country_select], [:gender, :gender_select], [:years, :integer], :birthday
  ]

  SEARCHABLE_ATTRS = [
    :first_name, :last_name, :company_name, :nickname, :email, :street, :housenumber, :zip_code, :town,
    :country, :birthday, :additional_information, {phone_numbers: [:number],
                                                   social_accounts: [:name],
                                                   additional_emails: [:email]}
  ]

  GENDERS = %w[m w].freeze

  # rubocop:disable Style/MutableConstant meant to be extended in wagons
  LANGUAGES = Settings.application
    .languages
    .to_hash
    .merge(Settings.application.additional_languages&.to_hash || {})

  ADDRESS_ATTRS = %w[address_care_of street housenumber postbox zip_code town country]

  # rubocop:enable Style/MutableConstant meant to be extended in wagons

  # Configure which Person attributes can be used to identify a person for login.
  class_attribute :devise_login_id_attrs, default: [:email]

  # define devise before other modules
  devise :database_authenticatable,
    :lockable,
    :recoverable,
    :rememberable,
    :trackable,
    :timeoutable,
    :validatable,
    :confirmable

  include Groups
  include Contactable
  include DeviseOverrides
  include Encryptable
  include I18nSettable
  include I18nEnums
  include ValidatedEmail
  include TwoFactorAuthenticatable
  include PersonTags::ValidationTagged
  include People::SelfRegistrationReasons
  include People::MembershipVerification
  include FullTextSearchable

  i18n_enum :gender, GENDERS
  i18n_setter :gender, (GENDERS + [nil])
  i18n_boolean_setter :company

  has_one_attached :picture do |attachable|
    attachable.variant :thumb, resize_to_fill: [32, 32]
  end

  def picture_default
    "profile.svg"
  end

  def picture_thumb_default
    "profile.svg"
  end

  class_attribute :used_attributes
  self.used_attributes = PUBLIC_ATTRS + INTERNAL_ATTRS

  model_stamper
  stampable stamper_class_name: :person,
    deleter: false

  has_paper_trail meta: {main_id: ->(p) { p.id }, main_type: sti_name},
    skip: Person::INTERNAL_ATTRS

  acts_as_taggable

  strip_attributes except: [:zip_code]

  ### ASSOCIATIONS

  has_many :roles, inverse_of: :person
  has_many :roles_unscoped, -> { with_inactive },
    class_name: "Role", foreign_key: "person_id", inverse_of: :person
  has_many :roles_with_ended_readable, -> { with_ended_readable },
    class_name: "Role", foreign_key: "person_id", inverse_of: :person

  has_many :groups, through: :roles
  has_many :groups_with_roles_ended_readable, through: :roles_with_ended_readable,
    source: :group

  has_many :event_participations, class_name: "Event::Participation",
    dependent: :destroy,
    inverse_of: :person
  has_many :event_applications, class_name: "Event::Application",
    through: :event_participations,
    source: :application
  has_many :event_roles, class_name: "Event::Role",
    through: :event_participations,
    source: :roles
  has_many :events, through: :event_participations
  has_many :event_invitations, class_name: "Event::Invitation", dependent: :destroy

  has_many :event_responsibilities, class_name: "Event",
    foreign_key: :contact_id,
    inverse_of: :contact,
    dependent: :nullify

  has_many :group_responsibilities, class_name: "Group",
    foreign_key: :contact_id,
    inverse_of: :contact,
    dependent: :nullify

  has_many :qualifications, dependent: :destroy

  has_many :subscriptions, as: :subscriber, dependent: :destroy

  has_many :family_members, -> { includes(:person, :other) },
    inverse_of: :person,
    dependent: :destroy

  has_many :invoices, foreign_key: :recipient_id, inverse_of: :recipient

  has_many :add_requests, dependent: :destroy

  has_many :notes, dependent: :destroy, as: :subject

  has_many :authored_notes, class_name: "Note",
    foreign_key: "author_id",
    inverse_of: :author,
    dependent: :destroy

  belongs_to :primary_group, class_name: "Group"
  belongs_to :last_label_format, class_name: "LabelFormat"

  has_many :label_formats, dependent: :destroy
  has_many :table_displays, dependent: :destroy

  has_many :assignments, dependent: :destroy

  has_many :access_grants, class_name: "Oauth::AccessGrant",
    foreign_key: :resource_owner_id,
    inverse_of: :person,
    dependent: :delete_all

  has_many :access_tokens, class_name: "Oauth::AccessToken",
    foreign_key: :resource_owner_id,
    inverse_of: :person,
    dependent: :delete_all

  has_many :message_recipients, dependent: :nullify

  FeatureGate.if("people.family_members") do
    accepts_nested_attributes_for :family_members, allow_destroy: true
  end

  attr_accessor :household_people_ids, :shared_access_token

  ### VALIDATIONS

  validates_by_schema except: [:email, :data_quality]
  validates :email, length: {allow_nil: true, maximum: 255} # other email validations by devise
  validates :company_name, presence: {if: :company?}
  validates :language, inclusion: {in: LANGUAGES.keys.map(&:to_s)}
  validates :birthday,
    timeliness: {type: :date, allow_blank: true, before: Date.new(10_000, 1, 1)}
  validates :additional_information, length: {allow_nil: true, maximum: (2**16) - 1}
  validate :assert_has_any_name

  validates :picture, dimension: {width: {max: 8_000}, height: {max: 8_000}},
    content_type: ["image/jpeg", "image/gif", "image/png"]
  # more validations defined by devise

  normalizes :email, :unconfirmed_email, with: ->(attribute) { attribute.downcase }

  ### CALLBACKS

  before_validation :override_blank_email
  after_update :schedule_duplicate_locator
  before_destroy :destroy_roles
  before_destroy :destroy_person_duplicates
  after_save :update_household_address

  ### Scopes

  scope :household, -> { where.not(household_key: nil) }
  scope :with_address, -> {
    where.not(street: [nil, ""])
      .where.not(zip_code: [nil, ""])
      .where.not(town: [nil, ""])
      .where("(last_name IS NOT NULL AND last_name <> '') OR " \
          "(company_name IS NOT NULL AND company_name <> '')")
  }
  scope :with_mobile, -> { joins(:phone_numbers).where(phone_numbers: {label: "Mobil"}) }
  scope :preload_picture, -> { includes(picture_attachment: :blob) }

  scope :preload_roles_unscoped, -> { extending(PreloadRolesUnscoped) }
  scope :preload_roles, ->(roles_scope) { preload_roles_unscoped.roles_scope(roles_scope) }

  ### CLASS METHODS

  class << self
    def order_by_name
      select(order_by_name_statement).order(order_by_name_statement)
    end

    def order_by_name_statement
      Arel.sql(
        <<~SQL.squish
          CASE
            WHEN people.company THEN people.company_name
            WHEN people.last_name IS NOT NULL AND people.first_name IS NOT NULL THEN people.last_name || ' ' || people.first_name
            WHEN people.last_name IS NOT NULL THEN people.last_name
            WHEN people.first_name IS NOT NULL THEN people.first_name
            WHEN people.nickname IS NOT NULL THEN people.nickname
            ELSE ''
          END
        SQL
      )
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
        [key.to_sym, {label: Person.human_attribute_name(key), type: type}]
      end.to_h
    end

    def tags
      Person.tags_on(:tags).order(:name).pluck(:name)
    end

    def root
      find_by(email: Settings.root_email)
    end

    private

    def company_case_column(if_company, otherwise)
      "CASE WHEN people.company = #{connection.quoted_true} " \
        "THEN people.#{if_company} ELSE people.#{otherwise} END"
    end
  end

  ### ATTRIBUTE INSTANCE METHODS

  # Used to enable login with any of the attributes configured in `devise_login_id_attrs`
  def login_identity
    @login_identity || Array.wrap(devise_login_id_attrs).map do |key|
      send(key).presence
    end.compact.first
  end
  attr_writer :login_identity

  def basic_permissions_only?
    roles&.all?(&:basic_permissions_only)
  end

  def privacy_policy_accepted?
    privacy_policy_accepted_at.present?
  end
  alias_method :privacy_policy_accepted, :privacy_policy_accepted?

  def privacy_policy_accepted=(value)
    self.privacy_policy_accepted_at = if %w[1 yes true].include?(value.to_s.downcase)
      Time.now.utc
    end
  end

  def to_s(format = :default)
    if company? && company_name.present?
      company_name
    else
      person_name(format)
    end
  end

  def person_name(format = :default)
    name = full_name(format)
    if PUBLIC_ATTRS.include?(:nickname) && nickname? && format != :print_list
      name << " / #{nickname}"
    end
    name
  end

  def full_name(format = :default)
    case format
    when :list, :print_list then "#{last_name} #{first_name}".strip
    else "#{first_name} #{last_name}".strip
    end
  end

  def household
    @household ||= ::Household.new(self)
  end

  def household_people
    Person
      .where(id: household_people_ids).or(
        Person.where.not(household_key: nil).where(household_key: household_key)
      )
      .where.not(id: id)
      .includes(:groups)
  end

  def greeting_name
    first_name.presence || nickname.presence || last_name.presence || company_name
  end

  def default_group_id
    primary_group_id || groups.first.try(:id) || Group.root.id
  end

  def years(comparison = Time.zone.now.to_date)
    return unless birthday?

    birthday_has_passed =
      (comparison.month > birthday.month) ||
      (comparison.month == birthday.month && comparison.day >= birthday.day)

    comparison.year - birthday.year - (birthday_has_passed ? 0 : 1)
  end

  def login_status
    return :blocked if blocked?
    return :two_factors if two_factor_authentication
    return :login if email? && password?
    return :password_email_sent if reset_password_period_valid?

    :no_login
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

  # Is this person blocked?
  def blocked?
    has_attribute?(:blocked_at) && blocked_at?
  end

  ### OTHER INSTANCE METHODS

  def save(**) # rubocop:disable Rails/ActiveRecordOverride Overwritten to handle uniqueness validation race conditions
    super
  rescue ActiveRecord::RecordNotUnique
    # TODO: it makes no sense to add this error indiscriminate on the email attribute
    errors.add(:email, :taken)
    false
  end

  def layer_group
    primary_group&.layer_group
  end

  def finance_groups
    groups_with_permission(:finance)
      .flat_map(&:layer_group)
      .uniq
  end

  def table_display_for(table_model_class)
    @table_display ||= TableDisplay.for(self, table_model_class)
  end

  def oauth_applications
    application_ids = (access_grants.active + access_tokens.active).collect(&:application_id)
    Oauth::Application.where(id: application_ids)
  end

  def person_duplicates
    PersonDuplicate.where(person_1: id).or(PersonDuplicate.where(person_2: id)) # rubocop:disable Naming/VariableNumber
  end

  def remove_picture
    false
  end

  def remove_picture=(deletion_param)
    if %w[1 yes true].include?(deletion_param.to_s.downcase) && picture.persisted?
      picture.purge_later
    end
  end

  def address_attrs
    attributes.slice(*Person::ADDRESS_ATTRS).symbolize_keys
  end

  private

  def override_blank_email
    self.email = nil if email.blank?
  end

  def assert_has_any_name
    if !company? && first_name.blank? && last_name.blank? && nickname.blank?
      errors.add(:base, :name_missing)
    end
  end

  # Destroy all related roles before destroying this person.
  # dependent: :destroy does not work here, because roles are paranoid.
  def destroy_roles
    roles.with_inactive.delete_all
  end

  def destroy_person_duplicates
    person_duplicates.delete_all
  end

  def schedule_duplicate_locator
    changed_attrs = previous_changes.keys
    duplicate_attrs = People::DuplicateConditions::ATTRIBUTES.map(&:to_s)

    return unless changed_attrs.any? { |a| duplicate_attrs.include?(a) }

    Person::DuplicateLocatorJob.new(id).enqueue!
  end

  def update_household_address
    return if household_key.nil? || (Person::ADDRESS_ATTRS & saved_changes.keys).empty? || saved_changes.key?("household_key")

    # do not use update context to not trigger all validations for all household members
    household.save!(context: :update_address)
  end
end
