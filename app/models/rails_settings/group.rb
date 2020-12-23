# frozen_string_literal: true

#  Copyright (c) 2020, CVP Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module RailsSettings
  class Group < RailsSettings::SettingObject

    ENCRYPTED_VALUES = %w(username password).freeze

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
        v = encrypt(v)
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
  end
end
