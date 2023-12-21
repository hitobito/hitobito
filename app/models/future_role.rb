# frozen_string_literal: true

#
# Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
# hitobito_sac_cas and licensed under the Affero General Public License version 3
# or later. See the COPYING file at the top-level directory or at
# https://github.com/hitobito/hitobito

class FutureRole < Role
  self.kind = :future
  self.basic_permissions_only = true

  IGNORED_ATTRS = %w(id type convert_on convert_to created_at terminated).freeze

  skip_callback :create, :after, :set_first_primary_group
  skip_callback :create, :after, :set_contact_data_visible
  skip_callback :destroy, :after, :reset_contact_data_visible
  skip_callback :destroy, :after, :reset_primary_group

  after_commit :update_version_type

  validates :person, :group, presence: true
  validates :convert_to, inclusion: { within: :group_role_types }, if: :group
  validates_date :convert_on, on_or_after: -> { Time.zone.today }
  validates_date :delete_on,
                 if: :delete_on,
                 on_or_after: :convert_on,
                 on_or_after_message: :must_be_later_than_created_at

  validate :target_type_validations, if: :validate_target_type?

  def to_s(format = :default)
    model_name = convert_to_model_name
    unless format == :short
      model_name = "#{model_name} (#{formatted_start_date})"
    end
    model_name
  end

  def convert!
    Role.transaction do
      create_new_role!
      really_destroy!
    end
  end

  def destroy(always_soft_destroy: false)
    really_destroy!
  end

  # If this method returns true, then on validating the FutureRole instance, the validity
  # of the target type will also be checked and errors will be added to the FutureRole instance.
  # Override this method in wagon if target_type validity should be checked on FutureRole.
  # See SacCas wagon for an example.
  def validate_target_type?
    false
  end

  def formatted_start_date
    I18n.t('global.start_on', date: I18n.l(convert_on))
  end

  private

  def update_version_type
    versions.update_all(item_type: 'FutureRole')
  end

  def target_type
    group.class.find_role_type!(convert_to)
  end

  def build_new_role
    target_type.new.tap do |role|
      role.attributes = relevant_attrs.merge(type: convert_to)
    end
  end

  def create_new_role!
    build_new_role.save!
  end

  def group_role_types
    group.role_types.map(&:sti_name)
  end

  def relevant_attrs
    attributes.except(*IGNORED_ATTRS).merge(group: group, created_at: Time.zone.now)
  end

  def convert_to_model_name
    convert_to.constantize.model_name.human
  end

  def target_type_validations
    becoming = build_new_role
    becoming.validate

    becoming_errors = becoming.errors.reject do |e|
      # A FutureRole will have a convert_on date in the future, this will become the
      # created_at date of the new role. But the created_at date cannot be in the future.
      # So we ignore this specific error.
      e.attribute == :created_at && e.options[:message] == :cannot_be_later_than_today
    end

    becoming_errors.each { |e| errors.import(e) }
  end
end
