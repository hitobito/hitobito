# frozen_string_literal: true

#  Copyright (c) 2012-2026, Die Mitte Schweiz. This file is part of
#  hitobito_cvp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_cvp.

require "spec_helper"

describe Messages::TextMessageDeliveryReportJob do
  let(:message) { messages(:sms) }
  let(:top_leader) { people(:top_leader) }
  let!(:mobile) { Fabricate(:phone_number, contactable: top_leader, label: "Mobil") }
  let(:ok_report) { {status: :ok, status_message: ""} }
  let(:failed_report) { {status: :failed, status_message: ""} }
  let(:ok_delivery_reports) do
    {status: :ok, delivery_reports: {recipient.id.to_s => ok_report}}
  end
  let!(:recipient) do
    MessageRecipient.create!(
      {
        message_id: message.id,
        person_id: top_leader.id,
        phone_number: mobile.number,
        state: :pending
      }
    )
  end

  let(:client_double) { double(:client) }

  before do
    allow(subject).to receive(:client).and_return(client_double)
  end

  subject { described_class.new(message) }

  context "on successfull delivery_reports" do
    it "updates recipient status as sent" do
      expect(client_double).to receive(:delivery_reports).and_return(ok_delivery_reports)

      subject.perform

      recipient.reload

      expect(recipient.state).to eq("sent")
    end
  end

  context "without delivery_reports" do
    let(:empty_ok_delivery_report) do
      {status: :ok, delivery_reports: {}}
    end

    it "updates recipient status as failed" do
      expect(client_double).to receive(:delivery_reports).and_return(empty_ok_delivery_report)

      subject.perform

      recipient.reload

      expect(recipient.state).to eq("failed")
    end
  end

  context "on a failed delivery" do
    let(:no_credit_available_msg) { "Not enough credits available." }
    let(:failed_delivery_report) do
      {
        status: :error,
        message: no_credit_available_msg,
        delivery_reports: {
          recipient.id.to_s => failed_report
        }
      }
    end

    it "marks message and recipients as failed if provider error" do
      expect(client_double).to receive(:delivery_reports).and_return(failed_delivery_report)

      subject.perform

      recipient.reload

      expect(recipient.state).to eq("failed")
      expect(recipient.error).to eq(no_credit_available_msg)
    end
  end

  context "with the provider settings of the group" do
    before do
      allow(subject).to receive(:client).and_call_original
      message.mailing_list.group.update!(text_message_username: "goofy",
        text_message_password: "max42")
    end

    it "fetches delivery reports with the group's credentials" do
      stub_request(:post, "https://json.aspsms.com/InquireDeliveryNotifications")
        .with { |request| JSON.parse(request.body).values_at("UserName", "Password") == %w[goofy max42] }
        .to_return(status: 200, body: {
          StatusCode: "1",
          StatusInfo: "OK",
          DeliveryNotifications: [{TransactionReferenceNumber: recipient.id.to_s, DeliveryStatus: "0"}]
        }.to_json)

      subject.perform

      expect(recipient.reload.state).to eq("sent")
    end
  end
end
