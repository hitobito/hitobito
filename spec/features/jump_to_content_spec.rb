# frozen_string_literal: true

#  Copyright (c) 2012-2026, Puzzle ITC. This file is part of
#  hitobito_pbs and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe "Jump to content link", js: true do
  before do
    sign_in
    visit root_path
  end

  it "should show link on first tab press" do
    expect(page).not_to have_content("Zum Hauptinhalt springen")
    page.send_keys(:tab)
    expect(page).to have_content("Zum Hauptinhalt springen")
    page.send_keys(:tab)
    expect(page).not_to have_content("Zum Hauptinhalt springen")
  end

  it "should jump to main content on click" do
    page.send_keys(:tab, :enter, :tab)
    page.evaluate_script("document.activeElement.path") == page.first("#main-content a").path
  end
end
