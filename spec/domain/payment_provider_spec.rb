# frozen_string_literal: true

#  Copyright (c) 2021, Die Mitte Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.
#

require 'spec_helper'

describe PaymentProvider do
  subject { described_class.new(payment_provider_config) }

  let(:payment_provider_config) { payment_provider_configs(:postfinance) }
  let(:epics_client) { double(:epics_client) }
  let(:payment_provider_setting) { subject.send(:payment_provider_setting) }

  before do
    expect(subject).to receive(:client).and_return(epics_client)
  end

  context 'initial_setup' do
    let(:bank_keys) do
      { 
        A006: Epics::Key.new(OpenSSL::PKey::RSA.generate(1024)),
        X002: Epics::Key.new(OpenSSL::PKey::RSA.generate(1024)),
        E002: Epics::Key.new(OpenSSL::PKey::RSA.generate(1024))
      }
    end

    it 'saves keys to config' do
      payment_provider_config.update(password: 'password')

      expect(epics_client).to receive(:dump_keys).and_return(JSON.generate(bank_keys))

      subject.initial_setup

      expect(payment_provider_config.keys).to include(bank_keys[:A006].to_s)
      expect(payment_provider_config.keys).to include(bank_keys[:X002].to_s)
      expect(payment_provider_config.keys).to include(bank_keys[:E002].to_s)
    end
  end

  context 'INI' do
    it 'sends INI order' do
      expect(epics_client).to receive(:INI).exactly(:once).and_return(true)

      subject.INI
    end

    it 'raises if INI order failes' do
      expect(epics_client).to receive(:INI).exactly(:once).and_return(false)

      expect do
        subject.INI
      end.to raise_error('INI request failed')
    end
  end

  context 'HIA' do
    it 'sends HIA order' do
      expect(epics_client).to receive(:HIA).exactly(:once).and_return(true)

      subject.HIA
    end

    it 'raises if HIA order failes' do
      expect(epics_client).to receive(:HIA).exactly(:once).and_return(false)

      expect do
        subject.HIA
      end.to raise_error('HIA request failed')
    end
  end

  context 'HPB' do
    let(:authentication_epics_key) { double(:authentication_key) }
    let(:encryption_epics_key) { double(:encryption_key) }

    let(:payment_provider_public_keys) { [authentication_epics_key, encryption_epics_key] }

    let(:encrypted_authentication_public_key) { digested_key(payment_provider_setting.authentication_hash) }
    let(:encrypted_encryption_public_key) { digested_key(payment_provider_setting.encryption_hash) }

    let(:wrong_encrypted_authentication_public_key) { digested_key('WR ON GA UT HE NT IC AT IO NK EY') }
    let(:wrong_encrypted_encryption_public_key) { digested_key('WR ON GE NC RY PT IO NK EY') }

    it 'sends HPB order' do
      expect(epics_client).to receive(:HPB).exactly(:once).and_return(payment_provider_public_keys)

      expect(authentication_epics_key).to receive(:public_digest).and_return(encrypted_authentication_public_key)
      expect(encryption_epics_key).to receive(:public_digest).and_return(encrypted_encryption_public_key)

      subject.HPB
    end

    it 'raises if HPB returns wrong authentication key' do
      expect(epics_client).to receive(:HPB).exactly(:once).and_return(payment_provider_public_keys)

      expect(authentication_epics_key).to receive(:public_digest).and_return(wrong_encrypted_authentication_public_key)
      expect(encryption_epics_key).to receive(:public_digest).and_return(encrypted_encryption_public_key)

      expect do
        subject.HPB
      end.to raise_error('Authentication public key does not match')
    end

    it 'raises if HPB returns wrong encryption key' do
      expect(epics_client).to receive(:HPB).exactly(:once).and_return(payment_provider_public_keys)

      expect(authentication_epics_key).to receive(:public_digest).and_return(encrypted_authentication_public_key)
      expect(encryption_epics_key).to receive(:public_digest).and_return(wrong_encrypted_encryption_public_key)

      expect do
        subject.HPB
      end.to raise_error('Encryption public key does not match')
    end

    it 'raises if HPB returns wrong authentication and encryption key' do
      expect(epics_client).to receive(:HPB).exactly(:once).and_return(payment_provider_public_keys)

      expect(authentication_epics_key).to receive(:public_digest).and_return(wrong_encrypted_authentication_public_key)
      expect(encryption_epics_key).to receive(:public_digest).and_return(wrong_encrypted_encryption_public_key)

      expect do
        subject.HPB
      end.to raise_error('Authentication and encryption public keys do not match')
    end
  end

  private

  def digested_key(key_string)
    Base64.encode64([key_string.gsub(' ', '').downcase].pack('H*'))
  end
end
