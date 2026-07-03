# Copyright (c) 2026. BienenSchweiz. This file is part of
# hitobito and licensed under the Affero General Public License version 3
# or later. See the COPYING file at the top-level directory or at
# https://github.com/hitobito/hitobito

require "rails_helper"

RSpec.describe PersonalDocument, type: :model do
  let(:label) { Fabricate(:personal_document_label, name: "Test Label") }

  subject(:personal_document) { Fabricate(:personal_document, label:) }

  context "#to_s" do
    it "renders the label" do
      expect(personal_document.to_s).to eq("Test Label")
    end

    it "renders label with filename for :long format" do
      expect(personal_document.to_s(:long)).to eq("Test Label (logo.png)")
    end
  end

  context "paper trail", versioning: true do
    it "creates a version on create" do
      expect do
        Fabricate(:personal_document, person: people(:bottom_member), author: people(:top_leader))
      end.to change(PaperTrail::Version, :count).by(1)
    end

    it "stores main_id and main_type pointing to the person" do
      version = personal_document.versions.last
      expect(version.main_id).to eq(personal_document.person_id)
      expect(version.main_type).to eq(Person.sti_name)
    end

    it "stores item_label using to_s(:long)" do
      version = personal_document.versions.last
      expect(version.item_label).to eq(personal_document.to_s(:long))
    end

    it "creates a version on update" do
      personal_document
      expect { personal_document.update!(description: "updated") }
        .to change { personal_document.versions.count }.by(1)
    end

    it "creates a version on destroy" do
      personal_document
      expect { personal_document.destroy }
        .to change(PaperTrail::Version, :count).by(1)
    end
  end
end
