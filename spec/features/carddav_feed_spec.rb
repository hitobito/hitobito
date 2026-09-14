# frozen_string_literal: true

#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

require "spec_helper"

describe :carddav_feed do
  before { sign_in(people(:root)) }

  it "is listed in the settings navigation" do
    visit label_formats_path

    expect(page.find("nav#page-navigation"))
      .to have_link("Adressbuch integrieren", href: carddav_feed_path, visible: :all)
  end

  it "expands its settings group when opened directly" do
    visit carddav_feed_path

    expect(page).to have_content "Meine Kontakte in Adressbuch integrieren"
    nav = page.find("nav#page-navigation")
    expect(nav).to have_link("Adressbuch integrieren", href: carddav_feed_path)
    expect(nav.find("li.collapse.show")).to have_link(href: carddav_feed_path)
  end
end
