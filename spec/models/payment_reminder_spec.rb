# encoding: utf-8

#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.
# == Schema Information
#
# Table name: payment_reminders
#
#  id         :integer          not null, primary key
#  invoice_id :integer          not null
#  message    :text(65535)
#  due_at     :date             not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

require "spec_helper"

describe PaymentReminder do

  let(:draft) { invoices(:invoice) }
  let(:sent)  { invoices(:sent) }

  it "creating a payment_reminder updates invoice" do
    due_at = sent.due_at + 2.weeks
    expect do
      Fabricate(:payment_reminder, invoice: sent, due_at: due_at)
    end.to change { [sent.due_at, sent.state] }
    expect(sent.due_at).to eq due_at
    expect(sent.state).to eq "reminded"
  end

  it "validates invoice is in state sent" do
    reminder = Invoice.new.payment_reminders.build
    expect(reminder).to have(1).error_on(:invoice)
  end

  it "validates due_at is set" do
    reminder = sent.payment_reminders.build
    expect(reminder).to have(1).error_on(:due_at)
  end

  it "validates due_at is after invoice.due_date" do
    reminder = sent.payment_reminders.build(due_at: sent.due_at)
    expect(reminder).to have(1).error_on(:due_at)
  end

end
