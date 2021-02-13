#  Copyright (c) 2014, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.
# == Schema Information
#
# Table name: additional_emails
#
#  id               :integer          not null, primary key
#  contactable_id   :integer          not null
#  contactable_type :string           not null
#  email            :string           not null
#  label            :string
#  public           :boolean          default(TRUE), not null
#  mailings         :boolean          default(TRUE), not null
#

require "spec_helper"

describe AdditionalEmail do
  after do
    I18n.locale = I18n.default_locale
  end

  context "label validation" do
    it "should not contain a dot at the end of a label" do
      a1 = Fabricate(:additional_email, label: "Foo")
      expect(a1).to be_valid

      a1.label = "Foo."
      expect(a1).not_to be_valid
    end
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

  context "#translated_label" do
    it "should return untranslated label as-is" do
      I18n.locale = :fr

      a1 = Fabricate(:additional_email, label: "Foo")
      expect(a1.label).to eq "Foo"
      expect(a1.translated_label).to eq "Foo"
    end

    it "should return translated label" do
      I18n.locale = :fr

      a2 = Fabricate(:additional_email, label: "Privat")
      expect(a2.label).to eq "Privat"
      expect(a2.translated_label).to eq "Privé"
    end
  end

  context ".normalize_label" do
    it "reuses existing label" do
      a1 = Fabricate(:additional_email, label: "Foo")
      a2 = Fabricate(:additional_email, label: "fOO")
      expect(a2.label).to eq("Foo")
    end

    it "should preserve untranslated label as-is" do
      I18n.locale = :fr

      a1 = Fabricate(:additional_email, label: "Foo")
      expect(a1.label).to eq "Foo"
    end

    it "should map label back to default language" do
      I18n.locale = :fr

      a2 = Fabricate(:additional_email, label: "privé")
      expect(a2.label).to eq "Privat"
    end
  end

  context "#available_labels" do
    subject { AdditionalEmail.available_labels }

    before do
      @settings_langs = Settings.application.languages
      Settings.application.languages = {de: "Deutsch", fr: "Français"}
    end

    after do
      Settings.application.languages = @settings_langs
    end

    it { is_expected.to include(Settings.additional_email.predefined_labels.first) }

    it "includes labels from database" do
      a = Fabricate(:additional_email, label: "Foo")
      is_expected.to include("Foo")
    end

    it "includes labels from database and predefined only once" do
      predef = Settings.additional_email.predefined_labels.first
      a = Fabricate(:additional_email, label: predef)
      expect(subject.count(predef)).to eq(1)
    end

    it "includes translated labels where available" do
      I18n.locale = :fr

      a1 = Fabricate(:additional_email, label: "Foo")
      a2 = Fabricate(:additional_email, label: "Privat")

      is_expected.to include("Foo", "Privé")
    end

    it "is sweeped for all languages if new label is added" do
      Rails.cache.clear

      expect(I18n.locale).to eq :de
      labels_de = AdditionalEmail.available_labels

      I18n.locale = :fr
      labels_fr = AdditionalEmail.available_labels

      expect(labels_de).not_to eq labels_fr

      a1 = Fabricate(:additional_email, label: "A new label")
      expect(AdditionalEmail.available_labels).to eq labels_fr + ["A new label"]

      I18n.locale = :de
      expect(AdditionalEmail.available_labels).to eq labels_de + ["A new label"]
    end
  end

  context "paper trails", versioning: true do
    let(:person) { people(:top_leader) }

    it "sets main on create" do
      expect {
        person.additional_emails.create!(label: "Foo", email: "bar@bar.com")
      }.to change { PaperTrail::Version.count }.by(1)

      version = PaperTrail::Version.order(:created_at, :id).last
      expect(version.event).to eq("create")
      expect(version.main).to eq(person)
    end

    it "sets main on update" do
      account = person.additional_emails.create(label: "Foo", email: "bar@bar.com")
      expect {
        account.update!(email: "bur@bur.com")
      }.to change { PaperTrail::Version.count }.by(1)

      version = PaperTrail::Version.order(:created_at, :id).last
      expect(version.event).to eq("update")
      expect(version.main).to eq(person)
    end

    it "sets main on destroy" do
      account = person.additional_emails.create(label: "Foo", email: "bar@bar.com")
      expect {
        account.destroy!
      }.to change { PaperTrail::Version.count }.by(1)

      version = PaperTrail::Version.order(:created_at, :id).last
      expect(version.event).to eq("destroy")
      expect(version.main).to eq(person)
    end
  end
end
