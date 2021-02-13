# encoding: utf-8

#  Copyright (c) 2018, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Person::Filter::List do
  it "empty filter works for normal user" do
    list = filter_list
    expect(list.all_count).to eq 1
    expect(list.entries.to_a).to have(1).items
  end

  it "empty filter works with root user" do
    list = filter_list(person: people(:root))
    expect(list.all_count).to eq 1
    expect(list.entries.to_a).to have(1).items
  end

  def filter_list(person: people(:top_leader), group: groups(:top_group), filter: PeopleFilter.new(name: "name"))
    described_class.new(group, person, filter)
  end
end
