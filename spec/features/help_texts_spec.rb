# frozen_string_literal: true

#  Copyright (c) 2026, CEVI Regionalverband ZH-SH-GL. This file is part of
#  hitobito_cevi and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe "Help texts", js: true do
  subject { page }

  let(:text) { "Personen wird angezeigt" }

  it "renders with closed help text by default" do
    help_texts(:people_action_index).update!(body: text)
    sign_in
    visit group_people_path(groups(:top_layer))
    expect(page).not_to have_css ".help-text", text: text
    find(".help-text-trigger i").click
    expect(page).to have_css ".help-text", text: text
  end

  it "renders with open help text if configured" do
    help_texts(:people_action_index).update!(start_open: true, body: text)
    sign_in
    visit group_people_path(groups(:top_layer))
    expect(page).to have_css ".help-text", text: text
    find(".help-text-trigger i").click
    expect(page).not_to have_css ".help-text", text: text
  end
end
