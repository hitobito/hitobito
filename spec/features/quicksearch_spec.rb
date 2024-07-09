#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe "Quicksearch", sphinx: true do
  context "with sphinx", sphinx: true do
    sphinx_environment(:people, :groups, :events) do
      it "finds people and groups", js: true do
        obsolete_node_safe do
          index_sphinx
          sign_in
          visit root_path

          fill_in "quicksearch", with: "top"

          dropdown = find('ul[role="listbox"]')
          expect(dropdown).to have_content("Top Leader, Supertown")
          expect(dropdown).to have_content("Top → TopGroup")
          expect(dropdown).to have_content("Top")
          expect(dropdown).to have_content("Top: Top Course (TOP-007)")
        end
      end
    end

    it "finds people by birthday", js: true do
      people(:top_leader).update!(birthday: Date.new(2002, 7, 11))

      index_sphinx
      sign_in
      visit root_path

      fill_in "quicksearch", with: "11.07.2002"

      dropdown = find('ul[role="listbox"]')
      expect(dropdown).to have_content("Top Leader, Supertown")
    end

    it "finds people by birthday substring", js: true do
      people(:top_leader).update!(birthday: Date.new(2002, 7, 11))
      people(:bottom_member).update!(birthday: Date.new(1993, 7, 11))

      index_sphinx
      sign_in
      visit root_path

      fill_in "quicksearch", with: "11.07"

      dropdown = find('ul[role="listbox"]')
      expect(dropdown).to have_content("Top Leader, Supertown")
      expect(dropdown).to have_content("Bottom Member, Greattown")
    end
  end

  it "renders clickable tables when submitting form via click", js: true do
    sign_in
    visit root_path
    fill_in "quicksearch", with: "top"
    find("button i.fa-search").click
    expect(page).not_to have_content "Bottom One"
    within(".nav") { click_on "Gruppen" }
    expect(page).to have_link "Bottom One"
  end
end
