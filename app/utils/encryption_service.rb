# frozen_string_literal: true

#  Copyright (c) 2021, CVP Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class EncryptionService
  @@cypher = 'aes-256-cbc'

  class << self
    def encrypt(value)
      cipher = OpenSSL::Cipher.new(@@cypher)
      cipher.encrypt
      cipher.key = encryption_key
      iv = cipher.random_iv
      cipher.iv = iv
      encrypted_value = cipher.update(value)
      encrypted_value << cipher.final
      { encrypted_value: base64_encode(encrypted_value), iv: base64_encode(iv) }
    end

    def decrypt(encrypted_data, iv)
      cipher = OpenSSL::Cipher.new(@@cypher)
      cipher.decrypt
      cipher.key = encryption_key
      cipher.iv = base64_decode(iv)
      decrypted_data = cipher.update(base64_decode(encrypted_data))
      decrypted_data << cipher.final
      decrypted_data
    end

    private

    def encryption_key
      Digest::SHA1.hexdigest(Rails.application.secret_key_base)[1..32]
    end

    def base64_encode(data)
      Base64.strict_encode64(data)
    end

    def base64_decode(data)
      Base64.strict_decode64(data)
    end
  end
end
