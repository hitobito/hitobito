#  Copyright (c) 2026, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe GroupsFilter do
  let(:groups_filter) {
    GroupsFilter.new(parent: groups(:top_layer), group_type: "Group::BottomGroup", active_at: 5.days.from_now)
  }

  it "returns all active groups of certain group_type at certain date" do
    expect(groups_filter.entries).to match_array [groups(:bottom_group_one_one),
      groups(:bottom_group_one_one_one),
      groups(:bottom_group_one_two),
      groups(:bottom_group_two_one)]
  end

  it "does not return archived groups" do
    groups(:bottom_group_one_one).archive!

    expect(groups_filter.entries).to match_array [groups(:bottom_group_one_one_one),
      groups(:bottom_group_one_two),
      groups(:bottom_group_two_one)]
  end

  it "does return archived group when it wasn't archived at active_at date" do
    groups(:bottom_group_one_one).update!(archived_at: 1.day.ago)
    groups_filter.active_at = 10.days.ago

    expect(groups_filter.entries).to match_array [groups(:bottom_group_one_one),
      groups(:bottom_group_one_one_one),
      groups(:bottom_group_one_two),
      groups(:bottom_group_two_one)]
  end
end
