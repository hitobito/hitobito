# frozen_string_literal: true

#  Copyright (c) 2026, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe "Person primary group", js: true do
  let(:person) { people(:bottom_member) }
  let(:layer) { groups(:bottom_layer_one) }
  let(:group) { groups(:bottom_group_one_one) }

  before do
    Fabricate(Group::BottomGroup::Member.sti_name, person:, group:)
    Fabricate(Group::BottomGroup::Leader.sti_name, person:, group:, start_on: 1.week.from_now)
    sign_in(people(:top_leader))
    visit group_person_path(layer, person)
  end

  it "keeps current and future roles sections separate when changing primary group" do
    find("a.group-#{group.id}").click

    expect(page).to have_css("a.group-#{group.id} i.fas.fa-star")
    expect(page).to have_css("h2", text: "Aktive Rollen", count: 1)
    expect(page).to have_css("h2", text: "Zukünftige Rollen", count: 1)
  end
end
