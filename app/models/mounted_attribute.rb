# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class MountedAttribute < ActiveRecord::Base
  belongs_to :entry, polymorphic: true

  serialize :value

  validates_by_schema

  before_save :encrypt_value, if: :value_changed?

  def config
    @config ||= MountedAttr::ClassMethods.store.config_for(entry_type.constantize,
                                                           key)
  end

  def casted_value
    case config.attr_type
    when :string
      value
    when :integer
      value.to_i
    when :encrypted
      decrypted_value
    end
  end

  def encrypt_value
    return unless config.attr_type.eql?(:encrypted)

    self.value = EncryptionService.encrypt(value.to_s)
  end

  def decrypted_value
    return '' if value.blank?

    encrypted_value = value[:encrypted_value]
    iv = value[:iv]
    EncryptionService.decrypt(encrypted_value, iv) if encrypted_value.present?
  end
end
