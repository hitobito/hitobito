
class MountedAttribute < ActiveRecord::Base
  belongs_to :entry, polymorphic: true

  serialize :value

  validates_by_schema

  before_save :encrypt_value, if: :value_changed?

  def config
    @config ||= MountedAttr::ClassMethods.store.config_for(self.entry_type.constantize,
                                                           self.key)
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

    self.value = EncryptionService.encrypt(self.value.to_s)
  end

  def decrypted_value
    encrypted_value = value[:encrypted_value]
    iv = value[:iv]
    EncryptionService.decrypt(encrypted_value, iv) if encrypted_value.present?
  end
end
