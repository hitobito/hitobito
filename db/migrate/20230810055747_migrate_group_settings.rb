# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class MigrateGroupSettings < ActiveRecord::Migration[6.1]

  def up
    say_with_time('create group attributes') do
      add_column :groups, :encrypted_text_message_username, :string
      add_column :groups, :encrypted_text_message_password, :string
      add_column :groups, :text_message_provider, :string, null: false, default: 'aspsms'
      add_column :groups, :text_message_originator, :string
      add_column :groups, :letter_address_position, :string, null: false, default: 'left'
      add_column :groups, :letter_logo, :string

      Group.reset_column_information
    end

    return unless table_exists?(:settings)

    say_with_time('migrate group settings to group attributes') do
      migrate_settings
    end

    say_with_time('remove obsolete settings table') do
      if LegacyGroupSetting.count.zero?
        drop_table :settings
      end
    end
  end

  def down
    say_with_time('revert mounted attributes to group settings') do
      revert_mounted_attributes
    end

    say_with_time('remove group attributes') do
      remove_column :groups, :encrypted_text_message_username
      remove_column :groups, :encrypted_text_message_password
      remove_column :groups, :text_message_provider
      remove_column :groups, :text_message_originator
      remove_column :groups, :letter_address_position
      remove_column :groups, :letter_logo
    end

    Group.reset_column_information
  end

  class LegacyGroupSetting < ActiveRecord::Base
    self.table_name = 'settings'

    has_one_attached :picture
    belongs_to :target, polymorphic: true

    serialize :value, Hash
  end

  private

  def migrate_settings
    LegacyGroupSetting.where(target_type: 'Group').find_each do |setting|
      group = setting.target
      values = setting.value
      values.each do |key, value|
        case key
        when 'encrypted_username'
          group.encrypted_text_message_username = values.delete(key)
        when 'encrypted_password'
          group.encrypted_text_message_password = values.delete(key)
        when 'provider'
          group.text_message_provider = values.delete(key)
        when 'originator'
          group.text_message_originator = values.delete(key)
        when 'address_position'
          group.letter_address_position = values.delete(key)
        end
      end

      # we only have one setting with an attached picture, so
      # we asume it's the letter_logo
      picture = rails_setting_active_storage_attachment(setting)
      move_attachment(picture, group) if picture

      group.save(validate: false)

      if values.empty?
        setting.destroy!
      else
        setting.save!
      end
    end
  end

  def rails_setting_active_storage_attachment(setting)
    ActiveStorage::Attachment.where(record_type: 'RailsSettings::SettingObject', record_id: setting.id).first
  end

  def move_attachment(attachment, group)
    ActiveStorage::Attachment
      .connection
      .exec_update(
        "UPDATE active_storage_attachments set record_type = 'Group', record_id = #{group.id}, " +
        "name = 'letter_logo' where id = #{attachment.id}"
      )
  end

  def revert_mounted_attributes
    create_settings_table
    relevant_group_ids = Group.where('encrypted_text_message_username IS NOT NULL OR ' \
                                     'encrypted_text_message_password IS NOT NULL OR ' \
                                     'text_message_provider IS NOT NULL OR ' \
                                     'text_message_originator IS NOT NULL OR ' \
                                     'letter_address_position IS NOT NULL').pluck(:id)
    Group.where(id: relevant_group_ids).find_each do |group|
      values_for_var = {
        messages_letter: {
          'address_position' => group.letter_address_position,
        },
        text_message_provider: {
          'encrypted_username' => group.encrypted_text_message_username,
          'encrypted_password' => group.encrypted_text_message_password,
          'provider' => group.text_message_provider,
          'originator' => group.text_message_originator
        }
      }

      values_for_var.each do |var, values|
        if values.values.any?(&:present?)
          setting = LegacyGroupSetting.find_or_create_by(target_type: 'Group',
                                                            target_id: group.id,
                                                            var: var)
          setting.value.merge!(values)

          setting.save(validate: false)
        end
      end
    end

    ActiveStorage::Attachment.where(name: 'letter_logo', record_type: 'Group').find_each do |attachment|
      setting = LegacyGroupSetting.find_or_create_by!(target_type: 'Group',
                                                         target_id: attachment.record_id,
                                                         var: :messages_letter)
      ActiveStorage::Attachment
        .connection
        .exec_update(
          "UPDATE active_storage_attachments set record_type = 'RailsSettings::SettingObject', record_id = #{setting.id}, " +
          "name = 'picture' where id = #{attachment.id}"
        )
    end
  end

  def create_settings_table
    return if table_exists?(:settings)

    create_table :settings do |t|
      t.string     :var, null: false
      t.text       :value
      t.references :target, null: false, polymorphic: true
      t.timestamps null: true
    end
    add_index :settings, [:target_type, :target_id, :var], unique: true

    LegacyGroupSetting.reset_column_information
  end
end
