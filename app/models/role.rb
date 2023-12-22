# frozen_string_literal: true

#  Copyright (c) 2012-2023, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# == Schema Information
#
# Table name: roles
#
#  id          :integer          not null, primary key
#  archived_at :datetime
#  convert_on  :date
#  convert_to  :string(255)
#  delete_on   :date
#  deleted_at  :datetime
#  label       :string(255)
#  type        :string(255)      not null
#  created_at  :datetime
#  updated_at  :datetime
#  group_id    :integer          not null
#  person_id   :integer          not null
#
# Indexes
#
#  index_roles_on_person_id_and_group_id  (person_id,group_id)
#  index_roles_on_type                    (type)
#

class Role < ActiveRecord::Base

  has_paper_trail meta: { main_id: ->(r) { r.person_id },
                          main_type: Person.sti_name },
                  skip: [:updated_at]

  acts_as_paranoid

  include Role::Types
  include NormalizedLabels
  include TypeId

  ### ATTRIBUTES

  # All attributes actually used (and mass-assignable) by the respective STI type.
  class_attribute :used_attributes
  self.used_attributes = [:label, :created_at, :deleted_at, :delete_on]

  # Attributes that may only be modified by people from superior layers.
  class_attribute :superior_attributes
  self.superior_attributes = []

  # Marks the role as terminatable by the user.
  class_attribute :terminatable, default: false, instance_accessor: false

  # TOTP as 2FA is enforced on this role.
  class_attribute :two_factor_authentication_enforced
  self.two_factor_authentication_enforced = false

  # Attributes that are ignored when merging roles
  class_attribute :merge_excluded_attributes
  self.merge_excluded_attributes = []

  # Flags the role as having only basic permissions.
  # People with only this role are not allowed to manage their mailing_lists,
  # events, use the navigation and so on.
  # See https://github.com/hitobito/hitobito_sww/issues/120
  class_attribute :basic_permissions_only
  self.basic_permissions_only = false

  FeatureGate.if('groups.nextcloud') do
    # Can be one of several types:
    #
    # String - Name of the nextcloud-group
    # String  - Name of the nextcloud-group
    # Boolean - Dynamic lookup of the nextcloud-group
    #           If true, then the attached Group should be referenced
    #           If false, no group for nextcloud is referenced
    # Symbol  - Identifier of an instance-method
    # Proc    - A proc that is called with the role
    #
    # Both Symbol and Proc are expected return something that is useful to Nextcloud.
    # It can either only return the name of the nextcloud-group or a Hash like this
    # { 'gid' => 'group-id-that-is-unique-in-nextcloud', 'displayName' => 'Name of Group' }
    class_attribute :nextcloud_group
    self.nextcloud_group = false

    NextcloudGroup = Struct.new(:gid, :displayName) do # rubocop:disable Lint/ConstantDefinitionInBlock
      def hash
        gid.hash
      end

      def to_h
        { 'gid' => gid, 'displayName' => displayName }
      end
    end
  end

  # If these attributes should change, create a new role instance instead.
  attr_readonly :person_id, :group_id, :type

  ### ASSOCIATIONS

  belongs_to :person
  belongs_to :group

  ### VALIDATIONS

  validates_by_schema

  validates_date :created_at,
                 allow_blank: true,
                 on_or_before: -> { Time.zone.today },
                 on_or_before_message: :cannot_be_later_than_today

  validates_date :delete_on,
                 allow_blank: true,
                 on_or_after: ->(r) { [r.created_at&.to_date, Time.zone.today].compact.min },
                 on_or_after_message: :must_be_later_than_created_at

  validate :assert_type_is_allowed_for_group, on: :create

  ### CALLBACKS

  after_create :set_contact_data_visible
  after_create :set_first_primary_group
  after_destroy :reset_contact_data_visible
  after_destroy :reset_primary_group

  after_create :reset_person_minimized_at
  before_save :prevent_changes, if: :archived?

  ### SCOPES

  scope :without_future, -> { where.not(type: FutureRole.sti_name) }
  scope :without_archived, -> { where(archived_at: nil) }
  scope :only_archived, -> { where.not(archived_at: nil).where(archived_at: ..Time.now.utc) }
  scope :future, -> { where(type: FutureRole.sti_name) }
  scope :inactive, -> { with_deleted.where('deleted_at IS NOT NULL OR archived_at <= ?',
                                           Time.now.utc) }

  ### CLASS METHODS

  class << self
    # Is the given attribute used in the current STI class
    def attr_used?(attr)
      used_attributes.include?(attr)
    end
  end

  ### INSTANCE METHODS

  delegate :layer_group, to: :group

  def to_s(format = :default)
    model_name = self.class.label
    unless format == :short
      model_name = label? ? "#{model_name} (#{label})" : model_name
      model_name += " (#{formatted_delete_date})" if delete_on
    end
    if format == :long
      I18n.t('activerecord.attributes.role.string_long', role: model_name, group: group.to_s)
    else
      model_name
    end
  end

  # Soft destroy if older than certain amount of days, hard if younger.
  # Set always_soft_destroy to true if you want to soft destroy even if the role is not old enough.
  def destroy(always_soft_destroy: false)
    if always_soft_destroy || old_enough_to_archive?
      super()
    else
      really_destroy!
    end
  end

  # Soft destroy if older than certain amount of days, hard if younger.
  # Set always_soft_destroy to true if you want to soft destroy even if the role is not old enough.
  def destroy!(always_soft_destroy: false)
    destroy(always_soft_destroy: always_soft_destroy) || _raise_record_not_destroyed
  end

  def terminatable?
    self.class.terminatable && # class is marked as terminatable
      !terminated? && # role is not already terminated
      !archived? && # role is not archived
      !deleted? # role is not deleted
  end

  # Overwritten setter to prevent direct assignment of terminated.
  # Use Roles::Termination instead.
  def terminated=(_value)
    raise 'do not set terminated directly, use Roles::Termination instead'
  end

  def terminated_on
    delete_on || deleted_at&.to_date if terminated?
  end

  def archived?
    archived_at.present?
  end

  def nextcloud_group
    FeatureGate.assert!('groups.nextcloud')

    info = nextcloud_group_details

    return if info.nil?

    case info
    when String then NextcloudGroup.new(info, info)
    when Hash then NextcloudGroup.new(info['gid'], info['displayName'])
    end
  end

  def start_on
    convert_on || created_at&.to_date || Time.zone.today
  end

  def end_on
    delete_on || deleted_at&.to_date
  end

  def outdated?
    deleted_at.nil? && (conversion_pending? || deletion_pending?)
  end

  def active_period
    start_on..end_on
  end

  def in_primary_group?
    group_id == person.primary_group_id
  end

  def formatted_delete_date
    [self.class.human_attribute_name('delete_on_in_name'), I18n.l(delete_on)].join(' ')
  end

  private

  def conversion_pending?
    convert_on.present? && convert_on <= Time.zone.today
  end

  def deletion_pending?
    delete_on.present? && delete_on <= Time.zone.today
  end

  def nextcloud_group_details
    return nil unless FeatureGate.enabled?('groups.nextcloud')

    case (setting = self.class.nextcloud_group)
    when String then { 'gid' => "hitobito-#{setting}", 'displayName' => setting }
    when true   then { 'gid' => group_id.to_s,         'displayName' => group.name }
    when Symbol then method(setting).call
    when Proc   then setting.call(self)
    end
  end

  # If this role has contact_data permissions, set the flag on the person
  def set_contact_data_visible
    if becomes(type.constantize).permissions.include?(:contact_data)
      person.update_column :contact_data_visible, true # rubocop:disable Rails/SkipsModelValidations intentional
    end
  end

  # If this role was the last one with contact_data permission, remove the flag from the person
  def reset_contact_data_visible
    if permissions.include?(:contact_data) &&
       !person.roles.collect(&:permissions).flatten.include?(:contact_data)
      person.update_column :contact_data_visible, false # rubocop:disable Rails/SkipsModelValidations intentional
    end
  end

  def set_first_primary_group
    if (deleted_at.nil? || deleted_at.future?) && person.roles.count <= 1
      person.update_column :primary_group_id, group_id # rubocop:disable Rails/SkipsModelValidations intentional
    end
  end

  def reset_primary_group
    if person.primary_group_id == group_id &&
        person.roles.where(group_id: group_id).count.zero?
      person.update_column :primary_group_id, alternative_primary_group.try(:id) # rubocop:disable Rails/SkipsModelValidations intentional
    end
  end

  def alternative_primary_group
    person.roles.order(updated_at: :desc).first.try(:group)
  end

  def assert_type_is_allowed_for_group
    return if type == FutureRole.sti_name

    if type && group && !group.role_types.collect(&:sti_name).include?(type)
      errors.add(:type, :type_not_allowed)
    end
  end

  def old_enough_to_archive?
    (Time.zone.now - created_at) > Settings.role.minimum_days_to_archive.days
  end

  def prevent_changes
    allowed = %w(archived_at updater_id)
    only_archival = changes
                    .reject { |_attr, (from, to)| from.blank? && to.blank? }
                    .keys.all? { |key| allowed.include? key }

    raise ActiveRecord::ReadOnlyRecord unless new_record? || only_archival
  end

  def reset_person_minimized_at
    person&.update_attribute(:minimized_at, nil) # rubocop:disable Rails/SkipsModelValidations
  end

  def paranoia_destroy_attributes
    delete_on&.past? ? super.merge(deleted_at: delete_on.midnight) : super
  end
end
