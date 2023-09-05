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

  def up
    say_with_time('create group attributes') do
      add_column :groups, :encrypted_text_message_username, :string
      add_column :groups, :encrypted_text_message_password, :string
      add_column :groups, :text_message_provider, :string, null: false, default: 'aspsms'
      add_column :groups, :text_message_originator, :string
      add_column :groups, :letter_address_position, :string, null: false, default: 'left'

      Group.reset_column_information
    end


    say_with_time('migrate group settings to group attributes') do
      migrate_settings
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
    end

    Group.reset_column_information
  end

  private

  def migrate_settings
    MigrationGroupSetting.find_each do |setting|
      group = setting.target if setting.target_type == 'Group'

      next unless group

      setting.value.each do |key, value|
        case key
        when :encrypted_username
          group.encrypted_text_message_username = value
        when :encrypted_password
          group.encrypted_text_message_password = value
        when :provider
          group.text_message_provider = value
        when :originator
          group.text_message_originator = value
        when :address_position
          group.letter_address_position = value
        when :picture
          attachment = setting.picture
          attachment.name = :'letter_logo'
          attachment.record = setting.target
          attachment.save!
        end

        group.save(validate: false)
      end
    end
  end

  def revert_mounted_attributes
    relevant_group_ids = Group.where('encrypted_text_message_username IS NOT NULL OR ' \
                                     'encrypted_text_message_password IS NOT NULL OR ' \
                                     'text_message_provider IS NOT NULL OR ' \
                                     'text_message_originator IS NOT NULL OR ' \
                                     'letter_address_position IS NOT NULL').pluck(:id)
    Group.where(id: relevant_group_ids).find_each do |group|
      values_for_var = {
        messages_letter: {
          address_position: group.letter_address_position,
        },
        text_message_provider: {
          encrypted_username: group.encrypted_text_message_username,
          encrypted_password: group.encrypted_text_message_password,
          provider: group.text_message_provider,
          originator: group.text_message_originator
        }
      }

      values_for_var.each do |var, values|
        if values.values.any?(&:present?)
          setting = MigrationGroupSetting.find_or_create_by(target_type: 'Group',
                                                            target_id: group.id,
                                                            var: var)
          setting.value.merge!(values)

          setting.save(validate: false)
        end
      end
    end

    ActiveStorage::Attachment.where(name: 'letter_logo', record_type: 'Group').find_each do |attachment|
      setting = MigrationGroupSetting.find_or_create_by!(target_type: 'Group',
                                                         target_id: attachment.record_id,
                                                         var: :messages_letter)
      attachment.name = :picture
      attachment.record = setting
      attachment.save!
    end
  end
end
