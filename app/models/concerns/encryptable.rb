module Encryptable
  extend ActiveSupport::Concern

  class_methods do
    def attr_encrypted(*attributes)
      attributes.each do |attribute|
        define_method("#{attribute}=".to_sym) do |value|
          return if value.nil?

          self.public_send(
            "encrypted_#{attribute}=".to_sym,
            EncryptionService.encrypt(value)
          )
        end

        define_method(attribute) do
          data = self.public_send("encrypted_#{attribute}".to_sym)
          encrypted_value = data[:encrypted_value]
          iv = data[:iv]
          EncryptionService.decrypt(encrypted_value, iv) if encrypted_value.present?
        end
      end
    end
  end
end
