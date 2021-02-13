# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# == Schema Information
#
# Table name: social_accounts
#
#  id               :integer          not null, primary key
#  contactable_id   :integer          not null
#  contactable_type :string           not null
#  name             :string           not null
#  label            :string
#  public           :boolean          default(TRUE), not null
#

require "spec_helper"

describe SocialAccount do

  context ".normalize_label" do

    it "reuses existing label" do
      a1 = Fabricate(:social_account, label: "Foo")
      a2 = Fabricate(:social_account, label: "fOO")
      expect(a2.label).to eq("Foo")
    end
  end

  context "#available_labels" do
    subject { SocialAccount.available_labels }
    it { is_expected.to include(Settings.social_account.predefined_labels.first) }

    it "includes labels from database" do
      a = Fabricate(:social_account, label: "Foo")
      is_expected.to include("Foo")
    end

    it "includes labels from database and predefined only once" do
      predef = Settings.social_account.predefined_labels.first
      a = Fabricate(:social_account, label: predef)
      expect(subject.count(predef)).to eq(1)
    end
  end

  context "paper trails", versioning: true do
    let(:person) { people(:top_leader) }

    it "sets main on create" do
      expect do
        person.social_accounts.create!(label: "Foo", name: "Bar")
      end.to change { PaperTrail::Version.count }.by(1)

      version = PaperTrail::Version.order(:created_at, :id).last
      expect(version.event).to eq("create")
      expect(version.main).to eq(person)
    end

    it "sets main on update" do
      account = person.social_accounts.create(label: "Foo", name: "Bar")
      expect do
        account.update!(name: "Bur")
      end.to change { PaperTrail::Version.count }.by(1)

      version = PaperTrail::Version.order(:created_at, :id).last
      expect(version.event).to eq("update")
      expect(version.main).to eq(person)
    end

    it "sets main on destroy" do
      account = person.social_accounts.create(label: "Foo", name: "Bar")
      expect do
        account.destroy!
      end.to change { PaperTrail::Version.count }.by(1)

      version = PaperTrail::Version.order(:created_at, :id).last
      expect(version.event).to eq("destroy")
      expect(version.main).to eq(person)
    end
  end
end
