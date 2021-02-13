# encoding: utf-8

#  Copyright (c) 2017 Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Event::KindsController, js: true do
  it "may add new preconditions" do
    obsolete_node_safe do
      sign_in
      visit edit_event_kind_path(event_kinds(:slk))

      expect(page).to have_selector(".precondition-grouping", text: "Group Lead")

      find("#add_precondition_grouping").click

      expect(page).to have_selector("select#event_kind_precondition_kind_ids")
      select("Super Lead", from: "event_kind_precondition_kind_ids")
      select("Quality Lead", from: "event_kind_precondition_kind_ids")
      select("Group Lead (for Leaders)", from: "event_kind_precondition_kind_ids")
      find("#precondition_fields button").click

      expect(page).to have_selector(".precondition-grouping", text: "Group Lead (for Leaders), Quality Lead und Super Lead")

      find("button.btn-primary").click

      expect(page).to have_selector("h1", text: "Kursarten")

      grouped_ids = event_kinds(:slk).reload.grouped_qualification_kind_ids("precondition", "participant")
      expect(grouped_ids).to eq([[qualification_kinds(:gl).id], qualification_kinds(:gl_leader, :ql, :sl).map(&:id)])
    end
  end

  it "may remove preconditions" do
    event_kinds(:slk).event_kind_qualification_kinds.create!(
      qualification_kind: qualification_kinds(:ql),
      category: "precondition",
      role: "participant",
      grouping: 2)

    obsolete_node_safe do
      sign_in
      visit edit_event_kind_path(event_kinds(:slk))

      expect(page).to have_selector(".precondition-grouping", count: 2)
      expect(page).to have_selector(".precondition-grouping", text: "oder Quality Lead")

      find(".precondition-grouping:first-child .remove-precondition-grouping").click
      expect(page).to have_selector(".precondition-grouping", text: "Quality Lead")

      find(".precondition-grouping:first-child .remove-precondition-grouping").click
      expect(page).to have_no_selector(".precondition-grouping")

      find("button.btn-primary").click

      expect(page).to have_selector("h1", text: "Kursarten")

      expect(event_kinds(:slk).reload.qualification_kinds("precondition", "participant").count).to eq(0)
    end
  end
end
