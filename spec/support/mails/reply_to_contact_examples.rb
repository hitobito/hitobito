# frozen_string_literal: true

#  Copyright (c) 2014-2026, CEVI Regionalverband ZH-SH-GL. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

shared_examples "reply_to_contact" do
  let(:contact) { Fabricate(:person, email: "kontakt@example.com") }

  it "is not set when use_contact_as_reply_to setting is disabled" do
    allow(Settings.event).to receive(:use_contact_as_reply_to).and_return(false)
    event.update!(contact: contact)
    expect(mail.reply_to).to be_nil
  end

  it "is set to the event contact's email when use_contact_as_reply_to setting is enabled" do
    allow(Settings.event).to receive(:use_contact_as_reply_to).and_return(true)
    event.update!(contact: contact)
    expect(mail.reply_to).to eq(["kontakt@example.com"])
  end

  it "is not set when the event has no contact" do
    allow(Settings.event).to receive(:use_contact_as_reply_to).and_return(true)
    event.update_column(:contact_id, nil)
    expect(mail.reply_to).to be_nil
  end
end
