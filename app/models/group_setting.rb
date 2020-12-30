# frozen_string_literal: true

#  Copyright (c) 2020, CVP Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# https://github.com/ledermann/rails-settings

class GroupSetting < RailsSettings::SettingObject

  ENCRYPTED_VALUES = %w(username password).freeze
  SETTINGS = {
    text_message_provider: [:username, :password, :provider]
  }.with_indifferent_access.freeze

  def attrs
    SETTINGS[var]
  end

  private

  def _get_value(name)
    if encrypted?(name)
      name = "encrypted_#{name}"
      encrypted_value = super(name)
      decrypt(encrypted_value) if encrypted_value.present?
    else
      super(name)
    end
  end

  def _set_value(name, v)
    if encrypted?(name)
      name = "encrypted_#{name}"
      v = encrypt(v) if v.present?
    end
    super(name, v)
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
