# frozen_string_literal: true

# Copyright (c) 2012-2025, Jungwacht Blauring Schweiz. This file is part of
# hitobito and licensed under the Affero General Public License version 3
# or later. See the COPYING file at the top-level directory or at
# https://github.com/hitobito/hitobito.

require "spec_helper"

describe :event_guest, js: true do
  subject { page }

  let(:course) { events(:top_course) }
  let(:person) { people(:bottom_member) }
  let(:top_layer) { groups(:top_layer) }
  let(:bottom_layer) { groups(:bottom_layer) }

  before do
    sign_in(person)
    visit "/de/list_courses?filter[since]=01.01.2012"
  end

  def deselect(group)
    find("div[data-value='#{group.id}'] a").click
    click_button "Suchen"
  end

  it "can deselect and select courses in layer via quicklink" do
    expect(page).to have_css "strong", text: "Top Course"
    expect(page).not_to have_text "Keine Einträge gefunden"
    deselect top_layer
    expect(page).to have_text "Keine Einträge gefunden"
    click_on "Top"
    expect(page).not_to have_text "Keine Einträge gefunden"
    expect(page).to have_css "strong", text: "Top Course"
  end

  it "can deselect and select courses in layer via quicklink" do
    deselect top_layer
    expect(page).to have_text "Keine Einträge gefunden"
    click_on "Alle Gruppen"
    expect(page).not_to have_text "Keine Einträge gefunden"
    expect(page).to have_css "strong", text: "Top Course"
  end
end
