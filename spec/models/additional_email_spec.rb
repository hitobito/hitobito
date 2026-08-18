#  Copyright (c) 2014, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.
require "spec_helper"

describe AdditionalEmail do
  after do
    I18n.locale = I18n.default_locale
  end

  describe "e-mail validation" do
    let(:add_email) { Fabricate(:additional_email, label: "Foo") }

    before { allow(Truemail).to receive(:valid?).and_call_original }

    it "does not allow invalid e-mail address" do
      add_email.email = "blabliblu-ke-email"

      expect(add_email).not_to be_valid
      expect(add_email.errors.messages[:email].first).to eq("ist nicht gültig")
    end

    it "does not allow e-mail address with non-existing domain" do
      add_email.email = "dude@gitsäuäniä.it"

      expect(add_email).not_to be_valid
      expect(add_email.errors.messages[:email].first).to eq("ist nicht gültig")
    end

    it "does not allow e-mail address with domain without mx record" do
      add_email.email = "dude@bluewin.com"

      expect(add_email).not_to be_valid
      expect(add_email.errors.messages[:email].first).to eq("ist nicht gültig")
    end

    it "does allow valid e-mail address" do
      add_email.email = "dude@puzzle.ch"

      expect(add_email).to be_valid
    end
  end

  describe "normalization" do
    let(:add_email) { Fabricate(:additional_email, label: "Foo") }

    it "downcases email" do
      add_email.email = "TesTer@gMaiL.com"
      expect(add_email.email).to eq "tester@gmail.com"
    end
  end

  context "paper trails", versioning: true do
    let(:person) { people(:top_leader) }

    it "sets main on create" do
      expect do
        person.additional_emails.create!(label: "Foo", email: "bar@bar.com")
      end.to change { PaperTrail::Version.count }.by(1)

      version = PaperTrail::Version.order(:created_at, :id).last
      expect(version.event).to eq("create")
      expect(version.main).to eq(person)
    end

    it "sets main on update" do
      account = person.additional_emails.create(label: "Foo", email: "bar@bar.com")
      expect do
        account.update!(email: "bur@bur.com")
      end.to change { PaperTrail::Version.count }.by(1)

      version = PaperTrail::Version.order(:created_at, :id).last
      expect(version.event).to eq("update")
      expect(version.main).to eq(person)
    end

    it "sets main on destroy" do
      account = person.additional_emails.create(label: "Foo", email: "bar@bar.com")
      expect do
        account.destroy!
      end.to change { PaperTrail::Version.count }.by(1)

      version = PaperTrail::Version.order(:created_at, :id).last
      expect(version.event).to eq("destroy")
      expect(version.main).to eq(person)
    end
  end
end
