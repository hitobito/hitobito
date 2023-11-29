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

  def to_s(_long = nil)
    "#{convert_to_model_name} (#{formatted_start_date})"
  end

  def convert!
    Role.transaction do
      create_new_role!
      really_destroy!
    end
  end

  def destroy(always_soft_destroy: false) # rubocop:disable Rails/ActiveRecordOverride
    really_destroy!
  end

  private

  def update_version_type
    versions.update_all(item_type: 'FutureRole') # rubocop:disable Rails/SkipsValidations
  end

  def create_new_role!
    type = group.class.find_role_type!(convert_to).new
    type.attributes = relevant_attrs.merge(type: convert_to)
    type.save!
  end

  def group_role_types
    group.role_types.map(&:sti_name)
  end

  def relevant_attrs
    attributes.except(*IGNORED_ATTRS).merge(group: group, created_at: Time.zone.now)
  end

  def formatted_start_date
    I18n.t('global.start_on', date: I18n.l(convert_on))
  end

  def convert_to_model_name
    convert_to.constantize.model_name.human
  end
end
