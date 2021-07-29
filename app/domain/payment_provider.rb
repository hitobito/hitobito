# frozen_string_literal: true

#  Copyright (c) 2021, Die Mitte Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class PaymentProvider
  def initialize(config)
    @config = config
  end

  def initial_setup
    @client = Epics::Client.setup(config.password,
                                  payment_provider_setting.url,
                                  payment_provider_setting.host_id,
                                  config.user_identifier,
                                  config.partner_identifier)

    config.update(keys: client.send(:dump_keys))
  end

  def INI
    ok = client.INI

    raise 'INI request failed' unless ok
  end

  def ini_letter
    @ini_letter ||= client.ini_letter(config.payment_provider)
  end

  def HIA
    ok = client.HIA

    raise 'HIA request failed' unless ok
  end

  def HPB
    bank_x, bank_e = client.HPB

    check_bank_public_keys!(bank_x, bank_e)
  end

  private

  attr_reader :config

  def check_bank_public_keys!(bank_x, bank_e)
    authentication_key_ok = correct_public_key?(bank_x,
                                                payment_provider_setting.authentication_hash)
    encryption_key_ok = correct_public_key?(bank_e,
                                            payment_provider_setting.encryption_hash)
    return if authentication_key_ok && encryption_key_ok
    
    if !authentication_key_ok && encryption_key_ok
      raise 'Authentication public key does not match'
    elsif authentication_key_ok && !encryption_key_ok
      raise 'Encryption public key does not match'
    else
      raise 'Authentication and encryption public keys do not match'
    end
  end

  def client
    @client ||= Epics::Client.new(config.keys,
                                  config.password,
                                  payment_provider_setting.url,
                                  payment_provider_setting.host_id,
                                  config.user_identifier,
                                  config.partner_identifier)
  end

  def payment_provider_setting
    @payment_provider_setting ||= Settings.payment_providers.select do |provider|
      provider.name == config.payment_provider
    end.first
  end

  def correct_public_key?(epics_key, hash)
    hash.gsub(' ', '').downcase == Base64.decode64(epics_key.public_digest).unpack("H*").join
  end
end
