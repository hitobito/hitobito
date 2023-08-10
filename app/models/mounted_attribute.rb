
class MountedAttribute < ActiveRecord::Base
  belongs_to :entry, polymorphic: true

  serialize :value

  validates_by_schema

  def casted_value(type)
    case type
    when :string
      value
    when :integer
      value.to_i
    when :encrypted
      decrypted_value
    end
  end

  def decrypted_value
    encrypted_value = value[:encrypted_value]
    iv = value[:iv]
    EncryptionService.decrypt(encrypted_value, iv) if encrypted_value.present?
  end
end
