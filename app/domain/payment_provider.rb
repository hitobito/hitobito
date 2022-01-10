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
    @client = Epics::Client.setup(@config.password,
                                  payment_provider_setting.url,
                                  payment_provider_setting.host_id,
                                  @config.user_identifier,
                                  @config.partner_identifier)

    @config.update(keys: client.send(:dump_keys))
  end

  # rubocop:disable Naming/MethodName the uppercase-method match the client and the spec
  def INI
    ok = client.INI

    raise PaymentProviders::EbicsError, 'INI request failed' unless ok
  end

  def ini_letter
    @ini_letter ||= client.ini_letter(@config.payment_provider)
  end

  def HIA
    ok = client.HIA

    raise PaymentProviders::EbicsError, 'HIA request failed' unless ok
  end

  def HPB
    bank_x, bank_e = client.HPB

    check_bank_public_keys!(bank_x, bank_e)
    @config.update!(status: :registered)

    true
  rescue Epics::Error::TechnicalError => e
    case e.code
    # Using the HPB request we're also checking
    # whether the client is registered (which is the case once the bank accepts the ini letter)
    # However, as long as the letter isn't accepted an EBICS_AUTHENTICATION_FAILED Error gets raised
    when '061001' #EBICS_AUTHENTICATION_FAILED
      false
    else
      raise e
    end
  end

  def XTC(document)
    raise ArgumentError, 'document is empty' if document.blank?

    client.send(:upload, PaymentProviders::Xtc, document)
  end

  def Z54(since_date = nil, until_date = nil)
    xml_files = client.send(:download_and_unzip, PaymentProviders::Z54, since_date, until_date)

    xml_files.map { |order_data| xml_from_order_data(order_data) }
  end
  # rubocop:enable Naming/MethodName

  private

  def check_bank_public_keys!(bank_x, bank_e)
    authentication_key_ok = correct_public_key?(bank_x,
                                                payment_provider_setting.authentication_hash)
    encryption_key_ok = correct_public_key?(bank_e,
                                            payment_provider_setting.encryption_hash)
    return true if authentication_key_ok && encryption_key_ok

    if !authentication_key_ok && encryption_key_ok
      raise PaymentProviders::EbicsError, 'Authentication public key does not match'
    elsif authentication_key_ok && !encryption_key_ok
      raise PaymentProviders::EbicsError, 'Encryption public key does not match'
    else
      raise PaymentProviders::EbicsError, 'Authentication and encryption ' \
                                             'public keys do not match'
    end
  end

  def client
    @client ||= Epics::Client.new(@config.keys,
                                  @config.password,
                                  payment_provider_setting.url,
                                  payment_provider_setting.host_id,
                                  @config.user_identifier,
                                  @config.partner_identifier)
  end

  def payment_provider_setting
    @payment_provider_setting ||= Settings.payment_providers.select do |provider|
      provider.name == @config.payment_provider
    end.first
  end

  def correct_public_key?(epics_key, hash)
    hash.gsub(' ', '').downcase == decoded_key_digest(epics_key)
  end

  def decoded_key_digest(key)
    Base64.decode64(key.public_digest).unpack('H*').join
  end

  def xml_from_order_data(order_data)
    order_data.sub(/^.*\<\?xml version=/m, '<?xml version=')
      .sub(/<\/Document>.*$/m, '</Document>')
  end
end
