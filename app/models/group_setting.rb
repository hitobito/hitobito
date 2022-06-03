# frozen_string_literal: true

#  Copyright (c) 2020-2022, CVP Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# == Schema Information
#
# Table name: settings
#
#  id          :bigint           not null, primary key
#  target_type :string(255)      not null
#  value       :text(65535)
#  var         :string(255)      not null
#  created_at  :datetime
#  updated_at  :datetime
#  target_id   :bigint           not null
#
# Indexes
#
#  index_settings_on_target_type_and_target_id          (target_type,target_id)
#  index_settings_on_target_type_and_target_id_and_var  (target_type,target_id,var) UNIQUE
#

# https://github.com/ledermann/rails-settings

class GroupSetting < RailsSettings::SettingObject

  mount_uploader :carrierwave_picture, GroupSetting::LogoUploader, mount_on: 'picture'
  has_one_attached :picture

  # rubocop:disable Metrics/LineLength
  validates :picture, dimension: { width: { max: 8_000 }, height: { max: 8_000 }, unless: :skip_validation },
                      content_type: { in: ['image/jpeg', 'image/gif', 'image/png'], unless: :skip_validation }
  # rubocop:enable Metrics/LineLength

  ENCRYPTED_VALUES = %w(username password).freeze
  SETTINGS = {
    text_message_provider: { username: nil, password: nil, provider: %w(aspsms), originator: nil },
    messages_letter: { picture: nil }
  }.with_indifferent_access

  def attrs
    SETTINGS[var].symbolize_keys.keys
  end

  def remove_picture
    false
  end

  def remove_picture=(deletion_param)
    if %w(1 yes true).include?(deletion_param.to_s.downcase)
      picture.purge_later
    end
  end

  private

  def skip_validation
    Rails.env.test? ||
      ENV['NOCHMAL_MIGRATION'].blank? # if not migrating RIGHT NOW, i.e. normal case
  end

  def _get_value(name)
    if encrypted?(name)
      name = "encrypted_#{name}"
      encrypted_value = value[name]
      decrypt(encrypted_value) if encrypted_value.present?
    else
      value[name] || default_value(name)
    end
  end

  def default_value(name)
    SETTINGS[var].try(:[], name).try(:first)
  end

  def _set_value(name, value)
    if encrypted?(name)
      name = "encrypted_#{name}"
      value = encrypt(value) if value.present?
    end
    super(name, value)
  end

  def encrypt(value)
    EncryptionService.encrypt(value)
  end

  def decrypt(value)
    encrypted_value = value[:encrypted_value]
    iv = value[:iv]
    EncryptionService.decrypt(encrypted_value, iv) if encrypted_value.present?
  end

  def encrypted?(name)
    ENCRYPTED_VALUES.include?(name)
  end

  def _setting?(method_name)
    attrs.include?(method_name)
  end

  class << self
    def settings
      SETTINGS
    end

    def list(group_id)
      vars = fetch(group_id).to_a
      existing_keys = vars.map(&:var)
      SETTINGS.keys.each do |s|
        if existing_keys.exclude?(s)
          vars << new(var: s)
        end
      end
      vars.sort_by(&:var)
    end

    private

    def fetch(group_id)
      where(target_id: group_id, target_type: Group.sti_name)
    end
  end
end
