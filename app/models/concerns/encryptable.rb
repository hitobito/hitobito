# frozen_string_literal: true

#  Copyright (c) 2021-2024, CVP Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Encryptable
  extend ActiveSupport::Concern

  class_methods do
    def attr_encrypted(*attributes) # rubocop:disable Metrics/MethodLength
      attributes.each do |attribute|
        define_method(:"#{attribute}=") do |value|
          return if value.blank? || value == send(attribute)

          send(
            :"encrypted_#{attribute}=",
            EncryptionService.encrypt(value)
          )
        end

        define_method(attribute) do
          data = send(:"encrypted_#{attribute}")
          return "" if data.blank?

          encrypted_value = data[:encrypted_value]
          iv = data[:iv]
          EncryptionService.decrypt(encrypted_value, iv) if encrypted_value.present?
        end
      end
    end
  end
end
