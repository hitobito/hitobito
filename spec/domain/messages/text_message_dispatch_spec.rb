# frozen_string_literal: true

#  Copyright (c) 2021, CVP Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Messages::TextMessageDispatch do
  let(:message)    { messages(:sms) }
  let(:top_leader) { people(:top_leader) }
  let!(:mobile1) { Fabricate(:phone_number, contactable: top_leader, label: "Mobil") }
  let!(:mobile2) { Fabricate(:phone_number, contactable: top_leader, label: "Mobil") }
  let!(:fixnet) { Fabricate(:phone_number, contactable: top_leader, label: "Festnetz") }

  subject { described_class.new(message, Person.where(id: top_leader.id)) }

  let(:client_double) { double(:client) }
  before { allow(subject).to receive(:client).and_return(client_double) }

  context "#run" do
    it "sends text messages to people's mobil numbers" do
      nr1regex = Regexp.new("\\#{mobile1.number}:[0-9]+")
      nr2regex = Regexp.new("\\#{mobile2.number}:[0-9]+")
      expect(client_double)
        .to receive(:send)
        .with(text: message.text, recipients: array_including(nr1regex, nr2regex))
        .and_return(status: :ok, message: "OK")

      delivery_reports = double(:hash)
      allow(delivery_reports).to receive(:[]).and_return(status: :ok, status_message: "Delivered")

      expect(client_double)
        .to receive(:delivery_reports)
        .and_return(status: :ok, message: "OK", delivery_reports: delivery_reports)

      subject.run

      expect(message.reload.success_count).to eq 2
      expect(message.failed_count).to eq 0
      expect(message.state).to eq("finished")

      recipients = message.message_recipients
      expect(recipients.count).to eq(2)

      recipients.each do |r|
        nrs = [mobile1.number, mobile2.number]
        expect(nrs).to include(r.phone_number)
        expect(r.state).to eq("sent")
        expect(r.error).to be_blank
      end
    end

    it "marks message and recipients as failed if wrong provider credentials" do
      nr1regex = Regexp.new("\\#{mobile1.number}:[0-9]+")
      nr2regex = Regexp.new("\\#{mobile2.number}:[0-9]+")
      expect(client_double)
        .to receive(:send)
        .with(text: message.text, recipients: array_including(nr1regex, nr2regex))
        .and_return(status: :auth_error, message: "Authorization failed.")

      expect(client_double)
        .not_to receive(:delivery_reports)

      subject.run

      expect(message.reload.success_count).to eq 0
      expect(message.failed_count).to eq 2
      expect(message.state).to eq("failed")

      recipients = message.message_recipients
      expect(recipients.count).to eq(2)

      recipients.each do |r|
        expect(r.state).to eq("failed")
        expect(r.error).to eq("Authorization failed.")
      end
    end

    it "marks message and recipients as failed if provider error" do
      nr1regex = Regexp.new("\\#{mobile1.number}:[0-9]+")
      nr2regex = Regexp.new("\\#{mobile2.number}:[0-9]+")
      expect(client_double)
        .to receive(:send)
        .with(text: message.text, recipients: array_including(nr1regex, nr2regex))
        .and_return(status: :error, message: "Not enough credits available. Please recharge your account to proceed.")

      expect(client_double)
        .not_to receive(:delivery_reports)

      subject.run

      expect(message.reload.success_count).to eq 0
      expect(message.failed_count).to eq 2
      expect(message.state).to eq("failed")

      recipients = message.message_recipients
      expect(recipients.count).to eq(2)

      recipients.each do |r|
        expect(r.state).to eq("failed")
        expect(r.error).to eq("Not enough credits available. Please recharge your account to proceed.")
      end
    end
  end

  context "#init_recipient_entries" do
    it "creates recipient entries with state pending" do
      expect do
        subject.send(:init_recipient_entries)
      end.to change { MessageRecipient.count }.by(2)

      recipient1 = message.message_recipients.find_by(phone_number: mobile1.number)
      expect(recipient1.state).to eq("pending")
      expect(recipient1.person_id).to eq(top_leader.id)
      recipient2 = message.message_recipients.find_by(phone_number: mobile2.number)
      expect(recipient2.state).to eq("pending")
      expect(recipient1.person_id).to eq(top_leader.id)
    end

    it "does not create any more recipient entries if already present" do
      MessageRecipient.create!(message: message,
                               person: top_leader,
                               phone_number: "42",
                               state: :pending)

      expect do
        subject.send(:init_recipient_entries)
      end.to change { MessageRecipient.count }.by(0)
    end
  end
end
