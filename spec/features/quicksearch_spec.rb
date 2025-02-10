#  Copyright (c) 2012-2024, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe "Quicksearch", js: true do
  before do
    sign_in
    visit root_path
  end

  it "finds people and groups" do
    obsolete_node_safe do
      fill_in "quicksearch", with: "top"

      dropdown = find('ul[role="listbox"]')
      expect(dropdown).to have_content("Top Leader, Greattown")
      expect(dropdown).to have_content("Top → TopGroup")

      fill_in "quicksearch", with: "Top Leader"
      expect(dropdown).to have_content("Top Leader, Greattown")
      expect(dropdown).not_to have_content("Top → TopGroup")

      fill_in "quicksearch", with: "TopGroup"
      expect(dropdown).not_to have_content("Top Leader, Greattown")
      expect(dropdown).to have_content("Top → TopGroup")

      fill_in "quicksearch", with: "Greattown"
      expect(dropdown).to have_content("Top Leader, Greattown")
      expect(dropdown).not_to have_content("Top → TopGroup")
    end
  end

  it "finds people by birthday" do
    people(:top_leader).update!(birthday: Date.new(2002, 7, 11))

    fill_in "quicksearch", with: "11.07.2002"

    dropdown = find('ul[role="listbox"]')
    expect(dropdown).to have_content("Top Leader, Greattown")
  end

  it "finds people by birthday substring" do
    people(:top_leader).update!(birthday: Date.new(2002, 7, 11))
    people(:bottom_member).update!(birthday: Date.new(1993, 7, 11))

    fill_in "quicksearch", with: "11.07"

    dropdown = find('ul[role="listbox"]')
    expect(dropdown).to have_content("Top Leader, Greattown")
    expect(dropdown).to have_content("Bottom Member, Greattown")
  end

  it "finds results when special characters in search term when confiriming with enter" do
    allow_any_instance_of(FullTextController).to receive(:only_result).and_return(nil)
    Fabricate(:phone_number, contactable: people(:top_leader), number: "+41 79 123 45 67")
    sign_in
    visit root_path
    fill_in "quicksearch", with: "+41 79"
    send_keys(:enter)
    expect(page).to have_current_path("/full?q=%2B41%2079")
    expect(page).to have_content("Top Leader")
  end

  it "does display event links when event does not have a name" do
    allow_any_instance_of(FullTextController).to receive(:only_result).and_return(nil)
    Event::Translation.where(event_id: events(:top_course).id).destroy_all
    fill_in "quicksearch", with: events(:top_course).number
    find("button i.fa-search").click
    expect(page).to have_link("[Kein Name]")
  end

  it "renders clickable tables when submitting form via click" do
    fill_in "quicksearch", with: "top"
    find("button i.fa-search").click
    expect(page).not_to have_content "TopGroup"
    within(".nav") { click_on "Gruppen" }
    expect(page).to have_link "TopGroup"
  end
end
