#  Copyright (c) 2012-2021, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Event::Filter do
  let(:layer) { groups(:top_layer) }
  let(:group) { Fabricate(Group::TopGroup.name.to_sym, name: "g1", parent: groups(:top_group)) }
  let(:year) { 2012 }
  let(:type) { nil }

  before do
    Fabricate(:event, groups: [group])
    Fabricate(:event, groups: [groups(:bottom_group_one_one)])
  end

  def filter(filter = nil, sort_expression = nil)
    described_class.new(layer, type, filter, year, sort_expression)
  end

  it "lists events of descendant groups by default" do
    expect(filter.list_entries).to have(3).entries
  end

  it "lists events of descendant groups for filter all" do
    expect(filter("all").list_entries).to have(3).entries
  end

  it "limits list to events of all non layer descendants" do
    expect(filter("layer").list_entries).to have(2).entries
  end

  it "sorts according to sort_expression" do
    expect(filter("layer", "event_translations.name").list_entries.first.name).to eq "Eventus"
    expect(filter("layer", "event_translations.name desc").list_entries.first.name).to eq "Top Event"
  end

  it "does not break with string sort condition" do
    expect(filter(nil, "event_dates.start_at asc").list_entries).to have(3).entries
  end

  it "does not break with pagination" do
    expect(filter(nil, "event_dates.start_at" => "asc").list_entries).to have(3).entries

    Fabricate.times(20, :event, groups: [group])

    expect(filter.list_entries).to have(23).entries
    expect(filter.list_entries.page(1).per(20)).to have(20).entries
    expect(filter.list_entries.page(2).per(20)).to have(3).entries
  end
end
