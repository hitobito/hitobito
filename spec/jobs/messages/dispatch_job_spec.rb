# frozen_string_literal: true

#  Copyright (c) 2012-2021, CVP Schweiz. This file is part of
#  hitobito_cvp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_cvp.


require 'spec_helper'

describe Messages::DispatchJob do
  let(:letter)     { messages(:letter) }
  let(:top_leader) { people(:top_leader) }

  context :letter do
    subject { Messages::DispatchJob.new(letter) }

    it 'updates message and creates message_recipients' do
      Subscription.create!(mailing_list: letter.mailing_list, subscriber: top_leader)
      subject.perform
      expect(letter.reload.state).to eq 'finished'
      expect(letter.sent_at).to be_present
      expect(letter.success_count).to eq 1
      expect(letter.failed_count).to eq 0
      expect(letter.message_recipients).to have(1).item

      recipient = letter.message_recipients.first
      expect(recipient.message).to eq letter
      expect(recipient.person).to eq top_leader
      expect(recipient.address).to eq "Top Leader\n\nSupertown\n"
    end
  end

  context :with_invoice do
    let(:message) { messages(:with_invoice) }

    subject { Messages::DispatchJob.new(message, sender) }

    pending 'creates reciepts invoices and invoice_list ' do
      subject.perform
    end
  end
end
