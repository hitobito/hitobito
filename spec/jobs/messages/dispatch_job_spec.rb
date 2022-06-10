# frozen_string_literal: true

#  Copyright (c) 2012-2021, CVP Schweiz. This file is part of
#  hitobito_cvp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_cvp.


require 'spec_helper'

describe Messages::DispatchJob do
  let(:letter)     { messages(:letter) }
  let(:top_leader) { people(:top_leader) }
  let(:bottom_member) { people(:bottom_member) }

  context :letter do
    let(:group) { groups(:bottom_layer_one) }

    subject { Messages::DispatchJob.new(letter) }

    before do
      top_leader.update(address: 'Greatstreet', zip_code: '1234', town: 'Greattown')
    end

    it 'updates message and creates message_recipients' do
      Subscription.create!(mailing_list: letter.mailing_list,
                           subscriber: group,
                           role_types: [Group::BottomLayer::Member])
      Fabricate(Group::BottomLayer::Member.name, group: group, person: top_leader)
      subject.perform
      expect(letter.reload.state).to eq 'finished'
      expect(letter.sent_at).to be_present
      expect(letter.failed_count).to eq 0
      expect(letter.message_recipients.reload.count).to eq 2
      expect(letter.recipient_count).to eq 2
      expect(letter.success_count).to eq 2
    end

    it 'updates household message and creates message_recipients' do
      letter.mailing_list.update(group: group)
      Subscription.create!(mailing_list: letter.mailing_list,
                           subscriber: group,
                           role_types: [Group::BottomLayer::Member])
      Fabricate(Group::BottomLayer::Member.name, group: group, person: top_leader)
      Fabricate(Group::BottomLayer::Member.name, group: group, person: bottom_member)
      top_leader.update(household_key: SecureRandom.uuid)
      bottom_member.update(household_key: top_leader.household_key)
      letter.update(send_to_households: true)

      subject.perform
      expect(letter.reload.state).to eq 'finished'
      expect(letter.sent_at).to be_present
      expect(letter.failed_count).to eq 0
      # 2 actual people are recipients, but only one household counts towards the total
      expect(letter.message_recipients.reload.count).to eq 2
      expect(letter.recipient_count).to eq 1
      expect(letter.success_count).to eq 1
    end

    it 'does not reschedule' do
      expect { subject.perform }.not_to change { Delayed::Job.count }
    end
  end

  context :with_invoice do
    let(:message) { messages(:with_invoice) }

    subject { Messages::DispatchJob.new(message) }

    pending 'creates reciepts invoices and invoice_list ' do
      expect_any_instance_of(Messages::LetterWithInvoiceDispatch).to receive(:perform)
      subject.perform
    end

    it 'does not reschedule' do
      expect { subject.perform }.not_to change { Delayed::Job.count }
    end
  end

  context :bulk_mail do
    let(:message) { messages(:mail) }

    subject { Messages::DispatchJob.new(message) }

    before do
      expect(Messages::BulkMail::AddressList).to receive_message_chain(:new, :entries)
        .and_return([{ person_id: top_leader.id, email: 'recipient@example.com' }])

      # Simulate all mails being correctly sent
      allow_any_instance_of(Messages::BulkMail::MailFactory).to receive_message_chain(:to, :deliver)
    end

    it 'does reschedule' do
      # Create recipients, should reschedule to send mails
      expect { subject.perform }.to change { Delayed::Job.count }.by(1)
      # All mails are sent in first batch, no rescheduling necessary
      expect { subject.perform }.to change { Delayed::Job.count }.by(0)
    end
  end
end
