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
#  first_name             :string
#  last_name              :string
#  company_name           :string
#  nickname               :string
#  company                :boolean          default(FALSE), not null
#  email                  :string
#  address                :string(1024)
#  zip_code               :string
#  town                   :string
#  country                :string
#  gender                 :string(1)
#  birthday               :date
#  additional_information :text
#  contact_data_visible   :boolean          default(FALSE), not null
#  created_at             :datetime
#  updated_at             :datetime
#  encrypted_password     :string
#  reset_password_token   :string
#  reset_password_sent_at :datetime
#  remember_created_at    :datetime
#  sign_in_count          :integer          default(0)
#  current_sign_in_at     :datetime
#  last_sign_in_at        :datetime
#  current_sign_in_ip     :string
#  last_sign_in_ip        :string
#  picture                :string
#  last_label_format_id   :integer
#  creator_id             :integer
#  updater_id             :integer
#  primary_group_id       :integer
#  failed_attempts        :integer          default(0)
#  locked_at              :datetime
#  authentication_token   :string
#

class Person < ActiveRecord::Base

  PUBLIC_ATTRS = [:id, :first_name, :last_name, :nickname, :company_name, :company,
                  :email, :address, :zip_code, :town, :country, :gender, :birthday,
                  :picture, :primary_group_id]

  INTERNAL_ATTRS = [:authentication_token, :contact_data_visible, :created_at, :creator_id,
                    :current_sign_in_at, :current_sign_in_ip, :encrypted_password, :id,
                    :last_label_format_id, :failed_attempts, :last_sign_in_at, :last_sign_in_ip,
                    :locked_at, :remember_created_at, :reset_password_token,
                    :reset_password_sent_at, :sign_in_count, :updated_at, :updater_id]

  GENDERS = %w(m w)


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

  has_many :qualifications, dependent: :destroy

  has_many :subscriptions, as: :subscriber, dependent: :destroy

  has_many :relations_to_tails, class_name: 'PeopleRelation',
                                dependent: :destroy,
                                foreign_key: :head_id

  has_many :add_requests, dependent: :destroy

  has_many :notes, class_name: 'Note',
                   dependent: :destroy

  has_many :authored_notes, class_name: 'Note',
                            foreign_key: 'author_id',
                            dependent: :destroy

  belongs_to :primary_group, class_name: 'Group'
  belongs_to :last_label_format, class_name: 'LabelFormat'

  accepts_nested_attributes_for :relations_to_tails, allow_destroy: true

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

    def mailing_emails_for(people)
      people = Array(people)
      emails = people.collect(&:email) +
               AdditionalEmail.mailing_emails_for(people)
      emails.select(&:present?).uniq
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
    name << " / #{nickname}" if nickname?
    name
  end

  def full_name(format = :default)
    case format
    when :list then "#{last_name} #{first_name}".strip
    else "#{first_name} #{last_name}".strip
    end
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
