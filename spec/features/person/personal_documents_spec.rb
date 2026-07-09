# frozen_string_literal: true

# Copyright (c) 2026. BienenSchweiz. This file is part of
# hitobito and licensed under the Affero General Public License version 3
# or later. See the COPYING file at the top-level directory or at
# https://github.com/hitobito/hitobito

require "spec_helper"

describe "Person::PersonalDocuments", js: true do
  let(:group) { groups(:top_group) }
  let(:person) { people(:bottom_member) }
  let!(:label) { Fabricate(:personal_document_label) }

  before { sign_in(people(:top_leader)) }

  it "uploads a document and shows it in the index" do
    visit group_person_personal_documents_path(group, person)

    click_on "Erstellen"

    expect(page).to have_selector("h1", text: "Dokument")

    select label.name, from: "Label"
    attach_file "Datei", Rails.root.join("spec", "fixtures", "files", "images", "logo.png"),
      visible: false

    expect do
      first(:button, "Speichern").click
      expect(page).to have_current_path(group_person_personal_documents_path(group, person, returning: true))
    end.to change(PersonalDocument, :count).by(1)

    expect(page).to have_content("logo.png")
  end
end
