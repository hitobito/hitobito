# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.
# == Schema Information
#
# Table name: people
#
#  id                        :integer          not null, primary key
#  first_name                :string(255)
#  last_name                 :string(255)
#  company_name              :string(255)
#  nickname                  :string(255)
#  company                   :boolean          default(FALSE), not null
#  email                     :string(255)
#  address                   :string(1024)
#  zip_code                  :string(255)
#  town                      :string(255)
#  country                   :string(255)
#  gender                    :string(1)
#  birthday                  :date
#  additional_information    :text(65535)
#  contact_data_visible      :boolean          default(FALSE), not null
#  created_at                :datetime
#  updated_at                :datetime
#  encrypted_password        :string(255)
#  reset_password_token      :string(255)
#  reset_password_sent_at    :datetime
#  remember_created_at       :datetime
#  sign_in_count             :integer          default(0)
#  current_sign_in_at        :datetime
#  last_sign_in_at           :datetime
#  current_sign_in_ip        :string(255)
#  last_sign_in_ip           :string(255)
#  picture                   :string(255)
#  last_label_format_id      :integer
#  creator_id                :integer
#  updater_id                :integer
#  primary_group_id          :integer
#  failed_attempts           :integer          default(0)
#  locked_at                 :datetime
#  authentication_token      :string(255)
#  show_global_label_formats :boolean          default(TRUE), not null
#  household_key             :string(255)
#

class Person < ActiveRecord::Base

  PUBLIC_ATTRS = [ # rubocop:disable Style/MutableConstant meant to be extended in wagons
    :id, :first_name, :last_name, :nickname, :company_name, :company,
    :email, :address, :zip_code, :town, :country, :gender, :birthday,
    :picture, :primary_group_id
  ]

  INTERNAL_ATTRS = [ # rubocop:disable Style/MutableConstant meant to be extended in wagons
    :authentication_token, :contact_data_visible, :created_at, :creator_id,
    :current_sign_in_at, :current_sign_in_ip, :encrypted_password, :id,
    :last_label_format_id, :failed_attempts, :last_sign_in_at, :last_sign_in_ip,
    :locked_at, :remember_created_at, :reset_password_token,
    :reset_password_sent_at, :sign_in_count, :updated_at, :updater_id,
    :show_global_label_formats, :household_key
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
         :validatable

  include Groups
  include Contactable
  include DeviseOverrides
  include I18nSettable
  include I18nEnums

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

  accepts_nested_attributes_for :relations_to_tails, allow_destroy: true

  attr_accessor :household_people_ids

  ### VALIDATIONS

  validates_by_schema except: [:email, :picture]
  validates :email, length: { allow_nil: true, maximum: 255 } # other email validations by devise
  validates :company_name, presence: { if: :company? }
  validates :birthday,
            timeliness: { type: :date, allow_blank: true, before: Date.new(10_000, 1, 1) }
  validates :additional_information, length: { allow_nil: true, maximum: 2**16 - 1 }
  validate :assert_has_any_name
  # more validations defined by devise


  ### CALLBACKS

  before_validation :override_blank_email
  before_validation :remove_blank_relations
  before_destroy :destroy_roles

  ### Scopes

  scope :household, -> { where.not(household_key: nil) }


  ### CLASS METHODS

  class << self
    def order_by_name
      order(order_by_name_statement)
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

    def filter_attrs_list
      Person::FILTER_ATTRS.collect do |attr|
        [Person.human_attribute_name(attr), attr]
      end.sort
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

  def years # rubocop:disable Metrics/AbcSize Age calculation is complex
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

  # Overwrite to handle uniquness validation race conditions and improper characters
  def save(*args)
    super
  rescue ActiveRecord::RecordNotUnique
    errors.add(:email, :taken)
    false
  rescue ActiveRecord::StatementInvalid => e
    raise e unless e.original_exception.message =~ /Incorrect string value/
    errors.add(:base, :emoji_suspected)
    false
  end

  def layer_group
    primary_group.layer_group if primary_group
  end

  def finance_groups
    groups_with_permission(:finance).
      flat_map(&:layer_group)
  end

  def table_display_for(parent)
    @table_display ||= TableDisplay.for(self, parent)
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

end
