# frozen_string_literal: true

#  Copyright (c) 2021, CVP Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Encryptable
  extend ActiveSupport::Concern

  class_methods do
    def attr_encrypted(*attributes)
      attributes.each do |attribute|
        define_method("#{attribute}=".to_sym) do |value|
          return if value.nil? || value.try(:empty?) || value == self.send(attribute)

          self.send(
            "encrypted_#{attribute}=".to_sym,
            EncryptionService.encrypt(value)
          )
        end

        define_method(attribute) do
          data = self.send("encrypted_#{attribute}".to_sym)
          return '' if data.nil?

          encrypted_value = data[:encrypted_value]
          iv = data[:iv]
          EncryptionService.decrypt(encrypted_value, iv) if encrypted_value.present?
        end
      end
    end
  end
end
