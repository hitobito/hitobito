# frozen_string_literal: true

#  Copyright (c) 2021, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe PaymentProviderConfig do
  let(:postfinance_config) { payment_provider_configs(:postfinance) }
  let(:ubs_config) { payment_provider_configs(:ubs) }

  it "encrypts keys" do
    postfinance_config.keys = "bla,bli,blup"

    expect(postfinance_config.encrypted_keys[:encrypted_value]).to be_present
    expect(postfinance_config.encrypted_keys[:iv]).to be_present
    expect(postfinance_config.encrypted_keys[:encrypted_value]).to_not eq("bla,bli,blup")
    expect(postfinance_config.keys).to eq("bla,bli,blup")

    expect(postfinance_config.save).to be(true)
  end

  it "encrypts password" do
    postfinance_config.password = "passwördli13!"

    expect(postfinance_config.encrypted_password[:encrypted_value]).to be_present
    expect(postfinance_config.encrypted_password[:iv]).to be_present
    expect(postfinance_config.encrypted_password[:encrypted_value]).to_not eq("password")
    expect(postfinance_config.password).to eq("passwördli13!")

    expect(postfinance_config.save).to be(true)
  end

  it "sets status to draft as default" do
    payment_provider_config = described_class.new

    expect(payment_provider_config.status).to eq("draft")
  end

  it "sets legacy_25_ebics to true as default" do
    payment_provider_config = described_class.new

    expect(payment_provider_config.legacy_25_ebics).to eq(true)
  end

  describe "#ebics_version" do
    it "returns EBICS 3.0 version when legacy_25_ebics is false" do
      postfinance_config.legacy_25_ebics = false

      expect(postfinance_config.ebics_version).to eq(Epics::Keyring::VERSION_30)
    end

    it "returns EBICS 2.5 version when legacy_25_ebics is true" do
      postfinance_config.legacy_25_ebics = true

      expect(postfinance_config.ebics_version).to eq(Epics::Keyring::VERSION_25)
    end
  end

  describe "#ebics_version_label" do
    it "returns EBICS 3.0 when legacy_25_ebics is false" do
      postfinance_config.legacy_25_ebics = false

      expect(postfinance_config.ebics_version_label).to eq("EBICS 3.0")
    end

    it "returns EBICS 2.5 when legacy_25_ebics is true" do
      postfinance_config.legacy_25_ebics = true

      expect(postfinance_config.ebics_version_label).to eq("EBICS 2.5")
    end
  end

  describe ".list" do
    it "orders configs by payment_provider and legacy_25_ebics" do
      ubs_config.update!(legacy_25_ebics: false)
      postfinance_config.update!(legacy_25_ebics: false)
      ubs_legacy = ubs_config.invoice_config.payment_provider_configs.create!(
        payment_provider: "ubs", legacy_25_ebics: true
      )

      expect(described_class.list).to eq([postfinance_config, ubs_config, ubs_legacy])
    end
  end
end
