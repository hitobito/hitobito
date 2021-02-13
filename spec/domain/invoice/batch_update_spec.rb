# encoding: utf-8

#  Copyright (c) 2018, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.
#

require "spec_helper"

describe Invoice::BatchUpdate do
  let(:person) { people(:top_leader) }
  let(:draft) { invoices(:invoice) }
  let(:sent) { invoices(:sent) }
  let(:results) { @results }

  def update(invoices, sender = nil)
    @results = Invoice::BatchUpdate.new(invoices, sender).call
  end

  it "changes invoice to state from draft to issued" do
    expect { update([draft]) }.to change { draft.state }.to "issued"
    expect(results.notice).to have(1).item
  end

  it "changes invoice to state from draft to sent, sends email" do
    expect do
      expect { update([draft], person) }.to change { draft.state }.to "sent"
    end.to change { Delayed::Job.count }.by(1)
    expect(results.notice).to have(2).items
  end

  it "changes invoice to state sent from issued, sends email" do
    draft.update(state: :issued)
    expect do
      expect { update([draft], person) }.to change { draft.state }.to "sent"
    end.to change { Delayed::Job.count }.by(1)
    expect(results.notice).to have(1).items
  end

  it "changes overdue invoice to state reminded, creates first reminder" do
    sent.update_columns(due_at: 31.days.ago)
    expect do
      expect { update([sent]) }.to change { sent.state }.to "reminded"
    end.to change { sent.payment_reminders.size }.by(1)
    expect(results.notice).to have(1).item
  end

  it "tracks error if invoice cannot be issued because no invoice_item is present" do
    invoice = Fabricate(:invoice, group: draft.group, recipient_email: "a@a.com")
    expect { update([invoice]) }.not_to change { sent.state }
    expect(results.alert).to have(1).item
    expect(results.notice).to be_empty
  end

  it "tracks error if invoice cannot be sent because no invoice_item is present" do
    invoice = Fabricate(:invoice, group: draft.group, recipient_email: "a@a.com")
    expect { update([invoice], person) }.not_to change { sent.state }
    expect(results.alert).to have(1).item
    expect(results.notice).to be_empty
  end

  it "tracks error if no reminder can be issued because config is missing" do
    sent.group.invoice_config.payment_reminder_configs.destroy_all
    sent.update_columns(due_at: 31.days.ago)
    expect { update([sent]) }.not_to change { sent.state }
    expect(results.alert).to have(1).item
  end

  it "does not change non draft invoice" do
    draft.update(state: :issued)
    expect { update([draft]) }.not_to change { draft.state }
    expect(results.alert).to have(1).item
  end

  it "does not change invoice to sent if recipient_email is missing" do
    draft.update(recipient_email: nil)

    expect do
      expect { update([draft], person) }.not_to change { draft.reload.state }
    end.not_to change { Delayed::Job.count }
    expect(results.alert).to have(1).item
  end

  context "reminders" do
    it "creates 1st reminder for overdue invoice" do
      sent.update_columns(due_at: 31.days.ago)
      expect do
        expect do
          expect { update([sent], person) }.to change { sent.state }.to "reminded"
        end.to change { sent.payment_reminders.size }.by(1)
      end.to change { Delayed::Job.count }.by(1)
      expect(results.notice).to have(2).items
      expect(sent.payment_reminders.first.level).to eq 1
    end

    it "does not create 2nd reminder invoice is not yet due" do
      sent.update(state: :reminded, due_at: 10.days.from_now)
      expect do
        expect { update([sent]) }.not_to change { sent.state }
      end.not_to change { sent.payment_reminders.size }
      expect(results.alert).to have(1).item
    end

    it "creates 2nd reminder for overdue invoice" do
      Fabricate(:payment_reminder, invoice: sent, due_at: 30.days.from_now)
      expect do
        travel_to 31.days.from_now do
          expect { update([sent]) }.not_to change { sent.state }
        end
      end.to change { sent.payment_reminders.size }.by(1)
      expect(sent.payment_reminders).to have(2).items
      expect(sent.payment_reminders.last.level).to eq 2
      expect(results.notice).to have(1).item
    end

    it "creates 3rd reminder for overdue invoice" do
      Fabricate(:payment_reminder, invoice: sent, due_at: 30.days.from_now)
      Fabricate(:payment_reminder, invoice: sent, due_at: 40.days.from_now, level: 2)
      expect do
        travel_to 41.days.from_now do
          expect { update([sent]) }.not_to change { sent.state }
        end
      end.to change { sent.payment_reminders.size }.by(1)
      expect(sent.payment_reminders).to have(3).items
      expect(sent.payment_reminders.last.level).to eq 3
      expect(results.notice).to have(1).item
    end

    it "creates 4th reminder for overdue invoice, does not increase level" do
      Fabricate(:payment_reminder, invoice: sent, due_at: 30.days.from_now)
      Fabricate(:payment_reminder, invoice: sent, due_at: 40.days.from_now, level: 2)
      Fabricate(:payment_reminder, invoice: sent, due_at: 50.days.from_now, level: 3)
      expect do
        travel_to 51.days.from_now do
          expect { update([sent]) }.not_to change { sent.state }
        end
      end.to change { sent.payment_reminders.size }.by(1)
      expect(sent.payment_reminders).to have(4).items
      expect(sent.payment_reminders.last.level).to eq 3
      expect(results.notice).to have(1).item
    end
  end
end
