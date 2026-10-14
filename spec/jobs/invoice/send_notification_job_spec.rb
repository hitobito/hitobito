#  Copyright (c) 2026, Schweizer Wanderwege. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Invoice::SendNotificationJob do
  let(:invoice) { invoices(:group_invoice) }
  let(:sender) { people(:top_leader) }

  it "sends the notification in the language of a group recipient" do
    invoice.recipient.update!(language: :fr)

    expect(InvoiceMailer).to receive(:notification) do
      expect(I18n.locale).to eq :fr
      double(deliver_now: true)
    end

    described_class.new(invoice, sender).perform
  end
end
