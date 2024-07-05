#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Event::RegisterMailer do
  before do
    SeedFu.quiet = true
    SeedFu.seed [Rails.root.join("db", "seeds")]
  end

  let(:group) { event.groups.first }
  let(:event) { events(:top_event) }

  let(:person) { Fabricate(:person, email: "fooo@example.com", reset_password_token: "abc") }
  let(:mail) { Event::RegisterMailer.register_login(person, group, event, "abcdef") }

  context "headers" do
    subject { mail }

    its(:subject) { should eq "Anmeldelink für Anlass" }
    its(:to) { should eq(["fooo@example.com"]) }
    its(:from) { should eq(["noreply@localhost"]) }
  end

  context "body" do
    subject { mail.body }

    it "renders placeholders" do
      is_expected.to match(/Top Event/)
      is_expected.to match(/#{person.first_name}/)
    end

    it "renders link" do
      is_expected.to match(/<a href="http:\/\/test.host\/groups\/#{group.id}\/events\/#{event.id}\?onetime_token=abcdef">/)
    end
  end

  context "with additional emails" do
    it "does not send to them" do
      Fabricate(:additional_email, contactable: person)
      expect(mail.to).to eq [person.email]
    end
  end
end
