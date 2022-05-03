# frozen_string_literal: true

#  Copyright (c) 2021, CVP Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Messages::BulkMailDispatch do
  let(:message) { messages(:mail) }
  let(:top_leader) { people(:top_leader) }
  let(:dispatch) { described_class.new(message, mail_factory) }
  let(:mail_factory) { double }

  let(:address_list) do
    [
      { person_id: top_leader.id, email: 'recipient1@example.com' },
      { person_id: top_leader.id, email: 'recipient2@example.com' }
    ]
  end

  before do
    allow(Truemail).to receive(:valid?).and_call_original
    Subscription.create!(mailing_list: mailing_lists(:leaders), subscriber: top_leader)
  end

  context '#run' do
    context 'without recipients' do
      it 'creates recipient entries with state pending' do
        expect(Messages::BulkMail::AddressList).to receive_message_chain(:new, :entries).and_return(address_list)

        expect do
          result = dispatch.run
          expect(result.needs_reenqueue?).to be_truthy
        end.to change { MessageRecipient.count }.by(2)

        message.reload

        recipient1 = message.message_recipients.first
        expect(recipient1.state).to eq('pending')
        expect(recipient1.error).to eq(nil)
        expect(recipient1.person_id).to eq(top_leader.id)

        recipient2 = message.message_recipients.second
        expect(recipient2.state).to eq('pending')
        expect(recipient2.error).to eq(nil)
        expect(recipient2.person_id).to eq(top_leader.id)
      end

      it 'creates recipient with state failed when email invalid' do
        expect(Messages::BulkMail::AddressList).to receive_message_chain(:new, :entries).and_return([{ person_id: top_leader.id, email: 'invalid.com' }])

        expect do
          result = dispatch.run
          expect(result.needs_reenqueue?).to be_falsey
        end.to change { MessageRecipient.count }.by(1)

        message.reload

        recipient1 = message.message_recipients.first
        expect(recipient1.state).to eq('failed')
        expect(recipient1.error).to eq('Invalid email')
        expect(recipient1.person_id).to eq(top_leader.id)
      end


    end

    context 'with recipients' do
      let(:recipient1_email) { 'recipient1@example.com' }
      let(:recipient2_email) { 'recipient2@example.com' }
      let!(:recipient1) { MessageRecipient.create!(message_id: message.id, person_id: top_leader.id, state: :pending, email: recipient1_email) }
      let!(:recipient2) { MessageRecipient.create!(message_id: message.id, person_id: top_leader.id, state: :pending, email: recipient2_email) }
      let(:delivery) { double }

      def setup_delivery
        expect(Messages::BulkMail::Delivery).to receive(:new)
          .with(
            mail_factory,
           [recipient1_email, recipient2_email],
            Messages::BulkMailDispatch::DELIVERY_RETRIES)
          .and_return(delivery)

        expect(delivery).to receive(:deliver)
        expect(delivery).to receive(:succeeded).and_return([recipient1_email])
        expect(delivery).to receive(:failed).and_return([recipient2_email])
      end

      it 'persists results' do
        setup_delivery

        expect(message).to receive(:update!).with(state: 'processing').and_call_original
        expect(message).to receive(:update!).with(state: 'finished', raw_source: nil).and_call_original
        expect(message).to receive(:update!)
          .with(failed_count: 1, success_count: 1).and_call_original

        result = dispatch.run
        expect(message.reload).to be_finished
        expect(result.needs_reenqueue?).to be_falsey

        [recipient1, recipient2].each(&:reload)
        expect(recipient1.state).to eq('sent')
        expect(recipient2.state).to eq('failed')

        expect(message.success_count).to eq(1)
        expect(message.failed_count).to eq(1)
      end

      it 'does not create any more recipient entries if already present' do
        setup_delivery

        expect do
          dispatch.run
        end.not_to change { MessageRecipient.count }
      end

      it 'deletes mail raw source after delivery to save storage' do
        setup_delivery

        dispatch.run

        expect(message.reload.raw_source).to be_nil
      end

      context 'on smtp server error' do

        before do
          expect(Messages::BulkMail::Delivery).to receive(:new)
            .with(
              mail_factory,
              [recipient1_email, recipient2_email],
              Messages::BulkMailDispatch::DELIVERY_RETRIES)
            .and_return(delivery)

          expect(delivery).to receive(:deliver).and_raise(Messages::BulkMail::Delivery::RetriesExceeded)
        end

        it 'marks message and recipient entries as failed' do
          result = dispatch.run
          expect(result.needs_reenqueue?).to be_falsey

          expect(message.reload).to be_failed
          expect(message.success_count).to eq(0)
          expect(message.failed_count).to eq(2)
          # keep mail source for analysis
          expect(message.raw_source).to be_present

          [recipient1, recipient2].each do |r|
            r.reload
            expect(r.state).to eq('failed')
            expect(r.error).to eq('SMTP server error')
          end
        end

        it 'marks message and recipient entries as failed but keeps already sent' do
          MessageRecipient.create!(message_id: message.id, person_id: top_leader.id, state: :sent, email: 'recipient3@example.com')

          result = dispatch.run
          expect(result.needs_reenqueue?).to be_falsey

          expect(message.reload).to be_failed
          expect(message.success_count).to eq(1)
          expect(message.failed_count).to eq(2)
        end

      end
    end
  end
end
