#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Person::SendLoginJob do
  let(:sender) { people(:top_leader) }
  let(:recipient) { people(:bottom_member) }

  before do
    SeedFu.quiet = true
    SeedFu.seed [Rails.root.join("db", "seeds")]
  end

  subject { Person::SendLoginJob.new(recipient, sender) }

  its(:parameters) do
    should == {recipient_id: recipient.id,
                sender_id: sender.id,
                locale: I18n.locale.to_s}
  end

  it "generates reset token" do
    expect(recipient.reset_password_token).to be_nil
    subject.perform
    expect(recipient.reload.reset_password_token).to be_present
  end

  it "sends email" do
    expect(LocaleSetter).to receive(:with_locale).with(person: recipient).and_call_original
    subject.perform
    expect(last_email).to be_present
    expect(last_email.body).to match(/Hallo #{recipient.greeting_name}/)
    expect(last_email.body).not_to match(/#{recipient.reload.reset_password_token}/)
  end

  context "with locale" do
    it "sends localized email" do
      expect(LocaleSetter).to receive(:with_locale).with(person: recipient).and_call_original
      recipient.update!(language: :fr)
      subject.perform
      expect(last_email).to be_present
      expect(last_email.body).to match(/Salut #{recipient.greeting_name}/)
    end
  end
end
