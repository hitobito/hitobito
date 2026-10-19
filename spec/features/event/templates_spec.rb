# frozen_string_literal: true

#  Copyright (c) 2026, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe "event templates", js: true do
  let(:top_layer) { groups(:top_layer) }

  before { sign_in(people(:top_leader)) }

  def click_save
    all("form .btn-group").first.click_button "Speichern"
  end

  [
    ["a layer event", -> { events(:top_event) }, :top_layer],
    ["a layer course", -> { events(:top_course) }, :top_layer],
    ["a subgroup event", -> { Fabricate(:event, groups: [groups(:top_group)]) }, :top_group]
  ].each do |label, source_builder, group_key|
    it "saves #{label} as template on the layer" do
      source = instance_exec(&source_builder)
      visit group_event_path(groups(group_key), source)

      click_link "Als Vorlage speichern"
      fill_in "Name", with: "Vorlage #{label}"
      click_save

      expect(page).to have_css("#main-content h1", text: "Eventvorlagen")
      expect(page).to have_text "Vorlage #{label}"
      template = Event.templates.find_by!(id: Event::Translation.where(name: "Vorlage #{label}").select(:event_id))
      expect(template.groups).to eq [top_layer]
      expect(template.type).to eq source.type
    end
  end

  it "creates an event from a template" do
    template = events(:template)
    visit group_events_path(top_layer)

    within(".btn-group.dropdown", text: "Anlass erstellen") { find(".dropdown-toggle").click }
    click_link template.name
    click_link "Daten"
    fill_in "event_dates_attributes_0_start_at_date", with: "01.01.2030"
    click_save

    expect(page).to have_text "wurde erfolgreich erstellt"
    event = Event.order(:id).last
    expect(event.name).to eq template.name
    expect(event.template).to eq false
    expect(event.groups).to eq [top_layer]
  end
end
