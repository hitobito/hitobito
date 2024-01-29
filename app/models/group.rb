# frozen_string_literal: true

#  Copyright (c) 2012-2023, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# == Schema Information
#
# Table name: groups
#
#  id                          :integer          not null, primary key
#  address                     :text(16777215)
#  country                     :string(255)
#  deleted_at                  :datetime
#  description                 :text(16777215)
#  email                       :string(255)
#  lft                         :integer
#  logo                        :string(255)
#  name                        :string(255)      not null
#  require_person_add_requests :boolean          default(FALSE), not null
#  rgt                         :integer
#  short_name                  :string(31)
#  town                        :string(255)
#  type                        :string(255)      not null
#  zip_code                    :integer
#  created_at                  :datetime
#  updated_at                  :datetime
#  contact_id                  :integer
#  creator_id                  :integer
#  deleter_id                  :integer
#  layer_group_id              :integer
#  parent_id                   :integer
#  updater_id                  :integer
#
# Indexes
#
#  index_groups_on_layer_group_id  (layer_group_id)
#  index_groups_on_lft_and_rgt     (lft,rgt)
#  index_groups_on_parent_id       (parent_id)
#  index_groups_on_type            (type)
#

class Group < ActiveRecord::Base # rubocop:disable Metrics/ClassLength
  include Group::NestedSet
  include Group::Types
  include Contactable
  include ValidatedEmail
  include Globalized
  include MountedAttr
  include Encryptable
  include I18nEnums

  PROVIDER_VALUES = %w(aspsms).freeze
  ADDRESS_POSITION_VALUES = %w(left right).freeze

  serialize :encrypted_text_message_username
  serialize :encrypted_text_message_password

  i18n_enum :letter_address_position, ADDRESS_POSITION_VALUES, scopes: false, queries: false
  attr_encrypted :text_message_username, :text_message_password

  acts_as_paranoid
  extend Paranoia::RegularScope
  has_paper_trail meta: { main_id: ->(g) { g.id }, main_type: sti_name },
                  skip: [:lft, :rgt, :layer_group_id, :deleter_id, :require_person_add_requests,
                         :updated_at, :updater_id]

  has_one_attached :logo
  has_one_attached :privacy_policy
  has_one_attached :letter_logo

  ### ATTRIBUTES

  # All attributes actually used (and mass-assignable) by the respective STI type.
  # This must contain the superior attributes as well.
  class_attribute :used_attributes
  self.used_attributes = [:name, :short_name, :email, :contact_id, :text_message_username,
                          :text_message_password, :text_message_provider, :text_message_originator,
                          :letter_address_position,
                          :address, :zip_code, :town, :country, :description]
  FeatureGate.if('groups.nextcloud') do
    used_attributes << :nextcloud_url
  end

  # Attributes that may only be modified by people from superior layers.
  class_attribute :superior_attributes
  self.superior_attributes = []

  class_attribute :archival_validation
  self.archival_validation = true

  class_attribute :static_name, default: false

  attr_readonly :type

  translates :custom_self_registration_title
  translates :privacy_policy_title

  ### CALLBACKS

  before_save :reset_contact_info
  before_save :prevent_changes, if: ->(g) { Group.archival_validation && g.archived? }
  after_create :create_invoice_config, if: :layer?

  protect_if :root? # Root group may not be destroyed
  protect_if :children_without_deleted

  stampable stamper_class_name: :person, deleter: true

  ### ASSOCIATIONS

  belongs_to :contact, class_name: 'Person'

  has_many :roles, dependent: :destroy, inverse_of: :group
  has_many :people, through: :roles

  has_many :people_filters, dependent: :destroy

  has_and_belongs_to_many :events, -> { includes(:translations) },
                          after_remove: :destroy_orphaned_event

  has_many :mailing_lists, dependent: :destroy
  has_many :subscriptions, as: :subscriber, dependent: :destroy

  has_many :calendars, inverse_of: :group, dependent: :destroy
  has_many :calendar_groups, inverse_of: :group, dependent: :destroy

  has_many :notes, as: :subject, dependent: :destroy

  has_many :person_add_requests,
           foreign_key: :body_id,
           inverse_of: :body,
           class_name: 'Person::AddRequest::Group',
           dependent: :destroy

  has_one :invoice_config, dependent: :destroy
  has_many :invoices
  has_many :invoice_lists
  has_many :invoice_articles, dependent: :destroy
  has_many :invoice_items, through: :invoices

  has_many :service_tokens,
           foreign_key: :layer_group_id,
           dependent: :destroy

  ### VALIDATIONS

  validates_by_schema except: [:logo, :address]
  validates :type, uniqueness: { scope: :parent_id }, if: :static_name
  validates :name, presence: true, unless: :static_name
  validates :email, format: Devise.email_regexp, allow_blank: true
  validates :description, length: { allow_nil: true, maximum: 2**16 - 1 }
  validates :address, length: { allow_nil: true, maximum: 1024 }
  validates :contact, permission: :show_full, allow_blank: true, if: :contact_id_changed?
  validates :contact, inclusion: { in: ->(group) { group.people.members } }, allow_nil: true
  validates :privacy_policy_title, length: { allow_nil: true, maximum: 64 }
  validates :self_registration_role_type, presence: { if: :main_self_registration_group? }

  validates :text_message_provider, inclusion: { in: PROVIDER_VALUES }, allow_nil: false
  validates :letter_address_position, inclusion: { in: ADDRESS_POSITION_VALUES }, allow_nil: false

  validate :assert_valid_self_registration_notification_email

  validates :logo, dimension: { width: { max: 8_000 }, height: { max: 8_000 } },
                   content_type: ['image/jpeg', 'image/gif', 'image/png']

  scope :without_archived, -> { where(archived_at: nil) }

  ### CLASS METHODS

  class << self

    # Is the given attribute used in the current STI class
    def attr_used?(attr)
      used_attributes.include?(attr)
    end

    # order groups by type. If a parent group is given, order the types
    # as they appear in possible_children, otherwise order them
    # hierarchically over all group types.
    def order_by_type(parent_group = nil)
      reorder(Arel.sql(order_by_type_stmt(parent_group))) # acts_as_nested_set default to new order
    end

    def order_by_type_stmt(parent_group = nil)
      types = with_child_types(parent_group)
      if types.present?
        statement = ["CASE #{Group.quoted_table_name}.type"]
        types.each_with_index do |t, i|
          statement << "WHEN '#{t.sti_name}' THEN #{i}"
        end
        statement << 'END,'
      end

      "#{statement.join(' ')} lft"
    end

    private

    def with_child_types(parent_group = nil)
      if parent_group
        [parent_group.class] + parent_group.possible_children
      else
        all_types
      end
    end

  end


  ### INSTANCE METHODS

  def to_s(_format = :default)
    name
  end

  def display_name
    short_name.presence || name
  end

  def display_name_downcase
    display_name.downcase
  end

  def with_layer
    layer? ? [self] : [layer_group, self]
  end

  ## readers and query methods for contact info
  [:address, :town, :zip_code, :country].each do |attribute|
    [attribute, :"#{attribute}?"].each do |method|
      define_method(method) do
        (contact && contact.public_send(method).presence) || super()
      end
    end
  end

  # create alias to call it again
  alias hard_destroy really_destroy!
  def really_destroy!
    # run nested_set callback on hard destroy
    # destroy_descendants_without_paranoia

    # load events to destroy orphaned later
    event_list = events.to_a
    invoice_list = invoices.to_a

    hard_destroy

    event_list.each { |e| destroy_orphaned_event(e) }
    invoice_list.each(&:destroy)
  end

  def decorator_class
    GroupDecorator
  end

  def person_duplicates
    if top?
      duplicates = PersonDuplicate.all
    elsif layer?
      duplicates = layer_person_duplicates
    end
    duplicates.includes(person_1: [{ roles: :group }, :groups, :primary_group],
                        person_2: [{ roles: :group }, :groups, :primary_group])
  end

  # TODO Concern?
  def archive!
    ActiveRecord::Base.transaction do
      self.archived_at = Time.zone.now
      Role.where(group_id: id).tap do |roles|
        roles.where(type: FutureRole.sti_name).delete_all
        roles.update_all(archived_at: archived_at)
        roles.where('delete_on >= ?', archived_at).update_all(delete_on: nil)
      end

      mailing_lists.destroy_all

      subscriptions.destroy_all

      self.save!
    end
  end

  def archived?
    archived_at.present?
  end

  def archivable?
    !archived? && children_without_deleted.none?
  end

  def addable_child_types
    static_name_children = possible_children.select(&:static_name).map(&:sti_name)
    existing_static_name_children = Group.
      without_deleted.
      where(parent_id: id, type: static_name_children).
      pluck(:type).uniq

    possible_children.select do |child_class|
      existing_static_name_children.exclude?(child_class.sti_name)
    end
  end

  def self_registration_active?
    Settings.groups&.self_registration&.enabled &&
      self_registration_role_type.present? &&
      decorate.allowed_roles_for_self_registration
              .include?(self_registration_role_type.constantize)
  end

  def path_args
    [self]
  end

  def assert_valid_self_registration_notification_email
    self.self_registration_notification_email = self_registration_notification_email.presence
    return unless self_registration_notification_email

    unless valid_email?(self_registration_notification_email)
      errors.add(:self_registration_notification_email, :invalid)
    end
  end

  def remove_privacy_policy
    false
  end

  def remove_privacy_policy=(deletion_param)
    if %w(1 yes true).include?(deletion_param.to_s.downcase)
      privacy_policy.purge_later
    end
  end

  def remove_logo
    false
  end

  def remove_logo=(deletion_param)
    if %w(1 yes true).include?(deletion_param.to_s.downcase)
      logo.purge_later
    end
  end

  def remove_letter_logo
    false
  end

  def remove_letter_logo=(deletion_param)
    if %w(1 yes true).include?(deletion_param.to_s.downcase)
      letter_logo.purge_later
    end
  end

  def name
    if static_name
      self.class.label
    else
      super
    end
  end

  def short_name
    if static_name
      self.class.label
    else
      super
    end
  end

  def name=(value)
    return if static_name

    super(value)
  end

  private

  def layer_person_duplicates
    duplicates = PersonDuplicate.joins(person_1: :roles).joins(person_2: :roles)
    group_ids = children.map(&:id) + [id]
    duplicates
      .where('roles.group_id IN (:group_ids) OR roles_people.group_id IN (:group_ids)',
             group_ids: group_ids)
  end

  def top?
    parent.nil?
  end

  def destroy_orphaned_event(event)
    if event.group_ids.blank? || event.group_ids == [id]
      event.destroy!
    end
  end

  def reset_contact_info
    if contact
      clear_contacts = { address: nil, town: nil, zip_code: nil, country: nil }
      assign_attributes(clear_contacts)
    end
  end

  def children_without_deleted
    children.without_deleted
  end

  module Paranoia
    def destroy_descendants
      # do not destroy descendants on soft delete
    end
  end

  prepend Group::Paranoia

  def create_invoice_config
    config = InvoiceConfig.new(group: self)
    config.save(validate: false) # otherwise the validations will block creation
  end

  def prevent_changes
    allowed = %w(archived_at updater_id)
    only_archival = changes
                    .reject { |_attr, (from, to)| from.blank? && to.blank? }
                    .keys.all? { |key| allowed.include? key }

    raise ActiveRecord::ReadOnlyRecord unless new_record? || only_archival
  end
end
