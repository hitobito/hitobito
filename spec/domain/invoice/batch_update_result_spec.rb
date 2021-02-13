# encoding: utf-8

#  Copyright (c) 2018, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.
#

require "spec_helper"

describe Invoice::BatchUpdateResult do
  let(:draft) { invoices(:invoice) }
  let(:sent)  { invoices(:sent) }

  it "tracks single invoice being issued" do
    subject.track_update(:issued, draft)
    expect(subject.notice).to eq ["Rechnung #{draft.sequence_number} wurde gestellt."]
  end

  it "tracks multiple invoice being issued" do
    subject.track_update(:issued, draft)
    subject.track_update(:issued, sent)
    expect(subject.notice).to eq ["2 Rechnungen wurden gestellt."]
  end

  it "tracks single invoice being sent" do
    subject.track_update(:issued, draft)
    subject.track_update(:send_notification, draft)
    expect(subject.notice).to eq ["Rechnung #{draft.sequence_number} wurde gestellt.",
                                  "Rechnung #{draft.sequence_number} wird im Hintergrund per E-Mail verschickt."]
  end

  it "tracks multiple invoices being sent" do
    subject.track_update(:issued, draft)
    subject.track_update(:send_notification, draft)
    subject.track_update(:issued, sent)
    subject.track_update(:send_notification, sent)
    expect(subject.notice).to eq ["2 Rechnungen wurden gestellt.",
                                  "2 Rechnungen werden im Hintergrund per E-Mail verschickt."]
  end

  it "tracks single invoice which could not be sent" do
    subject.track_update(:recipient_email_invalid, draft)
    expect(subject.notice).to eq ["Rechnung #{draft.sequence_number} konnte nicht " \
                                  "verschickt werden, da keine Empfänger E-Mail " \
                                  "hinterlegt ist."]

  end

  it "tracks multiple invoices which could not be sent" do
    subject.track_update(:recipient_email_invalid, draft)
    subject.track_update(:recipient_email_invalid, sent)
    expect(subject.notice).to eq ["2 Rechnungen konnten nicht " \
                                  "verschickt werden, da keine Empfänger E-Mails " \
                                  "hinterlegt sind."]
  end

  it "tracks model_error on single invoice" do
    invoice = Fabricate(:invoice, recipient_address: "a@a.com", group: sent.group)
    expect(invoice.update(state: :sent)).to be_falsey
    subject.track_model_error(invoice)
    expect(subject).to be_present
    expect(subject.alert).to eq ["Rechnung #{invoice.sequence_number} ist ungültig - " \
                                 "Rechnungsposten muss ausgefüllt werden."]
  end

end

