# frozen_string_literal: true

#  Copyright (c) 2012-2021, CVP Schweiz. This file is part of
#  hitobito_cvp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_cvp.


require "spec_helper"

describe Messages::DispatchJob do
  let(:letter)     { messages(:letter) }
  let(:top_leader) { people(:top_leader) }

  context :letter do
    subject { Messages::DispatchJob.new(letter) }

    it "updates message and creates message_recipients" do
      # Subscription.create!(mailing_list: letter.mailing_list, subscriber: top_leader)
      subject.perform
      expect(letter.reload.state).to eq "finished"
      expect(letter.sent_at).to be_present
      expect(letter.failed_count).to eq 0
    end
  end

  context :with_invoice do
    let(:message) { messages(:with_invoice) }

    subject { Messages::DispatchJob.new(message) }

    pending "creates reciepts invoices and invoice_list " do
      expect_any_instance_of(Messages::LetterWithInvoiceDispatch).to receive(:perform)
      subject.perform
    end
  end
end
