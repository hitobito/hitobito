# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class MigrateGroupSettings < ActiveRecord::Migration[6.1]

  VAR_MAPPING = {
    text_message_username: :text_message_provider,
    text_message_password: :text_message_provider,
    text_message_provider: :text_message_provider,
    text_message_originator: :text_message_provider,
    letter_address_position: :messages_letter,
    letter_logo: :messages_letter
  }

  KEY_MAPPING = {
    encrypted_username: :text_message_username,
    encrypted_password: :text_message_password,
    provider: :text_message_provider,
    originator: :text_message_originator,
    address_position: :letter_address_position,
    picture: :letter_logo
  }

  class MigrationGroupSetting < ActiveRecord::Base
    self.table_name = 'settings'

    has_one_attached :picture
    belongs_to :target, polymorphic: true

    serialize :value, Hash
  end

  class MigrationMountedAttribute < ActiveRecord::Base
    self.table_name = 'mounted_attributes'

    belongs_to :entry, polymorphic: true

    serialize :value
  end

  def up
    say_with_time('migrate group settings to mounted attributes') do
      migrate_settings
      drop_table(:settings)
    end
  end

  def down
    create_table :settings do |t|
      t.string     :var, null: false
      t.text       :value
      t.references :target, null: false, polymorphic: true
      t.timestamps null: true
    end
    add_index :settings, [:target_type, :target_id, :var], unique: true

    say_with_time('revert mounted attributes to group settings') do
      revert_mounted_attributes
    end
  end

  private

  def migrate_settings
    MigrationGroupSetting.find_each do |setting|
      setting.value.each do |key, value|
        next unless KEY_MAPPING.keys.include?(key)

        if key == :picture
          attachment = setting.picture
          attachment.name = KEY_MAPPING[key.to_sym]
          attachment.record = setting.target
          attachment.save!
        else
          MigrationMountedAttribute.create!(entry_type: setting.target_type,
                                            entry_id: setting.target_id,
                                            key: KEY_MAPPING[key.to_sym],
                                            value: value)
        end
      end
    end
  end

  def revert_mounted_attributes
    relevant_group_ids = MigrationMountedAttribute.where(entry_type: Group.sti_name).pluck(:entry_id)
    Group.where(id: relevant_group_ids).find_each do |group|
      values_for_var = { messages_letter: {}, text_message_provider: {} }

      MigrationMountedAttribute.where(entry: group).find_each do |a|
        values_for_var[VAR_MAPPING[a.key.to_sym]][KEY_MAPPING.invert[a.key.to_sym].to_s] = a.value
      end

      values_for_var.each do |var, values|
        setting = MigrationGroupSetting.create!(target_type: Group.sti_name,
                                                target_id: group.id,
                                                var: var,
                                                value: values)

        if group.respond_to?(:letter_logo) && group.letter_logo.attached?
          attachment = group.letter_logo
          attachment.name = :picture
          attachment.record = setting
          attachment.save!
        end
      end
    end
  end
end
