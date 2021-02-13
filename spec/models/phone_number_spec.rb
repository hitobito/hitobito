# encoding: utf-8

# == Schema Information
#
# Table name: phone_numbers
#
#  id               :integer          not null, primary key
#  contactable_id   :integer          not null
#  contactable_type :string           not null
#  number           :string           not null
#  label            :string
#  public           :boolean          default(TRUE), not null
#

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe PhoneNumber do
  context ".normalize_label" do
    it "reuses existing label" do
      a1 = Fabricate(:phone_number, label: "privat", number: "+41 44 123 45 67")
      expect(a1.label).to eq("Privat")
    end
  end

  context ".valid" do
    it "number must be present" do
      a1 = Fabricate.build(:phone_number, label: "privat", number: nil)
      expect(a1.valid?).to eq(false)
    end

    it "accepts swiss local number" do
      a1 = Fabricate.build(:phone_number, number: "0441234567")
      expect(a1.valid?).to eq(true)
    end

    it "accepts swiss number with +41 prefix" do
      a1 = Fabricate.build(:phone_number, number: "+41441234567")
      expect(a1.valid?).to eq(true)
    end

    it "rejects an invalid number" do
      a1 = Fabricate.build(:phone_number, number: "044123456")
      expect(a1.valid?).to eq(false)
    end

    it "formats the valid number" do
      a1 = Fabricate.build(:phone_number, number: "0441234567")
      expect(a1.valid?).to eq(true)
      expect(a1.number).to eq("+41 44 123 45 67")
    end
  end

  context "#available_labels" do
    subject { PhoneNumber.available_labels }

    it { is_expected.to include(Settings.phone_number.predefined_labels.first) }

    it "includes labels from database" do
      a = Fabricate(:phone_number, label: "Foo", number: "+41 44 123 45 67")
      is_expected.to include("Foo")
    end

    it "includes labels from database and predefined only once" do
      predef = Settings.phone_number.predefined_labels.first
      a = Fabricate(:phone_number, label: predef, number: "+41 44 123 45 67")
      expect(subject.count(predef)).to eq(1)
    end
  end

  context "paper trails", versioning: true do
    let(:person) { people(:top_leader) }

    it "sets main on create" do
      expect do
        person.phone_numbers.create!(label: "Foo", number: "+41 44 123 45 67")
      end.to change { PaperTrail::Version.count }.by(1)

      version = PaperTrail::Version.order(:created_at, :id).last
      expect(version.event).to eq("create")
      expect(version.main).to eq(person)
    end

    it "sets main on update" do
      account = person.phone_numbers.create(label: "Foo", number: "+41 44 123 45 67")
      expect do
        account.update!(number: "021 987 65 43")
      end.to change { PaperTrail::Version.count }.by(1)

      version = PaperTrail::Version.order(:created_at, :id).last
      expect(version.event).to eq("update")
      expect(version.main).to eq(person)
    end

    it "sets main on destroy" do
      account = person.phone_numbers.create(label: "Foo", number: "+41 44 123 45 67")
      expect do
        account.destroy!
      end.to change { PaperTrail::Version.count }.by(1)

      version = PaperTrail::Version.order(:created_at, :id).last
      expect(version.event).to eq("destroy")
      expect(version.main).to eq(person)
    end
  end
end
