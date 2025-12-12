# frozen_string_literal: true
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

  context "after_delete" do
    def jobs_for(provider)
      Delayed::Job.where(
        "handler LIKE ?",
        "%Payments::EbicsImportJob%payment_provider_config_id: #{provider.id}%"
      )
    end
    it "deletes all associated ebics import jobs" do
      Payments::EbicsImportJob.new(postfinance_config.id).enqueue!(run_at: 10.seconds.from_now)
      Payments::EbicsImportJob.new(ubs_config.id).enqueue!(run_at: 10.seconds.from_now)

      expect do
        postfinance_config.destroy!
      end.to change { Delayed::Job.count }.by(-1)

      expect(jobs_for(postfinance_config)).to be_empty
      expect(jobs_for(ubs_config)).to be_present
    end
  end
end
