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
#  end_on      :date
#  label       :string(255)
#  start_on    :date
#  terminated  :boolean          default(FALSE), not null
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
  has_paper_trail meta: {main_id: ->(r) { r.person_id },
                         main_type: Person.sti_name},
    skip: [:updated_at],
    on: [:create, :touch, :update]

  include Role::Types
  include NormalizedLabels
  include TypeId

  ### ATTRIBUTES

  # All attributes actually used (and mass-assignable) by the respective STI type.
  class_attribute :used_attributes
  self.used_attributes = [:label, :start_on, :end_on]

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

  FeatureGate.if("groups.nextcloud") do
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
        {"gid" => gid, "displayName" => displayName}
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

  validates_date :end_on,
    allow_blank: true,
    on_or_after: :start_on,
    on_or_after_message: :must_be_later_than_start_on,
    if: -> { start_on.present? }

  validate :assert_type_is_allowed_for_group, on: :create

  ### CALLBACKS

  before_save :prevent_changes, if: :archived?
  after_create :reset_person_minimized_at
  after_commit :set_contact_data_visible, if: :active?
  after_commit :set_first_primary_group, if: :active?

  ### SCOPES

  def self.active_scope(reference_date = Date.current)
    # we must use arel_table instead of custom sql,
    # otherwise `unscope` with a column name does not work
    where(arel_table[:start_on].lteq(reference_date.to_date).or(arel_table[:start_on].eq(nil)))
      .where(arel_table[:end_on].gteq(reference_date.to_date).or(arel_table[:end_on].eq(nil)))
  end

  default_scope { active_scope }
  scope :with_inactive, -> { unscope(where: [:start_on, :end_on]) }
  scope :active, ->(reference_date = Date.current) { with_inactive.active_scope(reference_date) }
  scope :inactive, -> {
    with_inactive.where(
      "archived_at <= :now OR end_on < :today",
      now: Time.current.utc,
      today: Date.current
    )
  }

  scope :without_archived, -> { where(archived_at: nil) }
  scope :only_archived, -> { where(archived_at: ..Time.current.utc) }

  scope :future, -> { with_inactive.where("start_on > :today", today: Date.current) }
  scope :ended, -> { with_inactive.where("end_on < :today", today: Date.current) }

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
      model_name += " (#{formatted_delete_date})" if end_on
    end
    if format == :long
      I18n.t("activerecord.attributes.role.string_long", role: model_name, group: group.to_s)
    else
      model_name
    end
  end

  # Keep an alias of the original destroy method for when we need to call it
  # without the customizations.
  alias_method :vanilla_destroy, :destroy

  # If the role is younger than the minimum days to archive, it gets destroyed.
  # If it has "archival age", we update the end_on attribute to yesterday instead of destroying it.
  # If `always_soft_destroy` is set to true, the role is always ended instead of destroyed.
  def destroy(always_soft_destroy: false) # rubocop:disable Rails/ActiveRecordOverride
    return super() unless always_soft_destroy || old_enough_to_archive?

    run_callbacks :destroy do
      end_on&.past? ? true : update(end_on: Date.current.yesterday)
    end
    _run_commit_callbacks
  end

  # Soft destroy if older than certain amount of days, hard if younger.
  # Set always_soft_destroy to true if you want to soft destroy even if the role is not old enough.
  def destroy!(always_soft_destroy: false)
    destroy(always_soft_destroy: always_soft_destroy) || _raise_record_not_destroyed
  end

  def really_destroy!
    vanilla_destroy
  end

  def terminatable?
    self.class.terminatable && # class is marked as terminatable
      !terminated? && # role is not already terminated
      !archived? && # role is not archived
      !ended? # role has ended
  end

  # Overwritten setter to prevent direct assignment of terminated.
  # Use Roles::Termination instead.
  def terminated=(_value)
    raise "do not set terminated directly, use Roles::Termination instead"
  end

  def terminated_on
    end_on if terminated?
  end

  def archived?
    archived_at.present?
  end

  def nextcloud_group
    FeatureGate.assert!("groups.nextcloud")

    info = nextcloud_group_details

    return if info.nil?

    case info
    when String then NextcloudGroup.new(info, info)
    when Hash then NextcloudGroup.new(info["gid"], info["displayName"])
    end
  end

  def ended?
    end_on? && end_on < Date.current
  end

  def active?(reference_time = Time.current)
    active_period.cover?(reference_time)
  end

  def active_period
    start_on..end_on
  end

  def in_primary_group?
    group_id == person.primary_group_id
  end

  def formatted_delete_date
    [self.class.human_attribute_name("end_on_in_name"), I18n.l(end_on)].join(" ")
  end

  private

  def nextcloud_group_details
    return nil unless FeatureGate.enabled?("groups.nextcloud")

    case (setting = self.class.nextcloud_group)
    when String then {"gid" => "hitobito-#{setting}", "displayName" => setting}
    when true then {"gid" => group_id.to_s, "displayName" => group.name}
    when Symbol then method(setting).call
    when Proc then setting.call(self)
    end
  end

  def assert_type_is_allowed_for_group
    if type && group && !group.role_types.collect(&:sti_name).include?(type)
      errors.add(:type, :type_not_allowed)
    end
  end

  def old_enough_to_archive?
    (Time.zone.now - created_at) > Settings.role.minimum_days_to_archive.days
  end

  def prevent_changes
    allowed = %w[archived_at updater_id]
    only_archival = changes
      .reject { |_attr, (from, to)| from.blank? && to.blank? }
      .keys.all? { |key| allowed.include? key }

    raise ActiveRecord::ReadOnlyRecord unless new_record? || only_archival
  end

  def reset_person_minimized_at
    person&.update_attribute(:minimized_at, nil) # rubocop:disable Rails/SkipsModelValidations
  end

  def set_contact_data_visible
    People::UpdateAfterRoleChange.new(person.reload).set_contact_data_visible
  end

  def set_first_primary_group
    People::UpdateAfterRoleChange.new(person.reload).set_first_primary_group
  end
end
