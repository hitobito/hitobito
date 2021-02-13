#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe EventsController, js: true do
  let(:event) do
    event = Fabricate(:course, kind: event_kinds(:slk), groups: [groups(:top_group)])
    event.dates.create!(start_at: 10.days.ago, finish_at: 5.days.ago)
    event
  end

  it "may set and remove contact from event" do
    obsolete_node_safe do
      sign_in
      visit edit_group_event_path(event.group_ids.first, event.id)

      # set contact
      fill_in "Kontaktperson", with: "Top"
      expect(find(".typeahead.dropdown-menu")).to have_content "Top Leader"
      find(".typeahead.dropdown-menu").click
      all("form .btn-toolbar").first.click_button "Speichern"

      # show event
      expect(find("aside")).to have_content "Kontakt"
      expect(find("aside")).to have_content "Top Leader"
      click_link "Bearbeiten"

      # remove contact
      expect(find("#event_contact").value).to eq("Top Leader")
      fill_in "Kontaktperson", with: ""
      all("form .btn-toolbar").first.click_button "Speichern"

      # show event again
      expect(page).to have_no_selector(".contactable")
    end
  end

  context "standard course description" do
    let(:form_path) { new_group_event_path(event.group_ids.first, event.id, event: {type: Event::Course}, format: :html) }

    context "if textarea is empty" do
      before do
        sign_in
        visit form_path
      end

      it "fills default description" do
        obsolete_node_safe do
          select "SLK (Scharleiterkurs)", from: "event_kind_id"
          expect(find("#event_description").value).to eq event.kind.general_information
        end
      end

      it "does not display description insertion link" do
        obsolete_node_safe do
          select "SLK (Scharleiterkurs)", from: "event_kind_id"
          expect(page).to have_selector(".standard-description-link", visible: false)
        end
      end
    end

    context "if textarea is not empty" do
      let(:prefill_description) { "Test description" }

      before do
        sign_in
        visit form_path

        fill_in "event_description", with: prefill_description
      end

      it "displays description insertion link" do
        obsolete_node_safe do
          select "SLK (Scharleiterkurs)", from: "event_kind_id"
          expect(page).to have_selector(".standard-description-link", visible: true)
        end
      end

      it "does not fill textarea" do
        obsolete_node_safe do
          select "SLK (Scharleiterkurs)", from: "event_kind_id"
          expect(find("#event_description").value).to eq prefill_description
        end
      end

      it "fills textarea if clicked on description insertion link" do
        obsolete_node_safe do
          select "SLK (Scharleiterkurs)", from: "event_kind_id"

          find(".standard-description-link").click

          concat_description = prefill_description + " " + event.kind.general_information
          expect(find("#event_description").value).to eq concat_description
        end
      end
    end
  end
end
