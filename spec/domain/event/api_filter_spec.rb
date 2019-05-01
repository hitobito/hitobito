#  Copyright (c) 2018, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Event::ApiFilter do

  let(:group)  { groups(:top_layer) }
  let!(:event) { Fabricate(:event, groups: [groups(:bottom_group_one_one)]) }
  let(:event2) { Fabricate(:event, groups: [groups(:bottom_group_one_one)]) }
  let(:today)  { Date.today }

  before do
    @g1 = Fabricate(Group::TopGroup.name.to_sym, name: 'g1', parent: groups(:top_group))
    Fabricate(:event_date, event: Fabricate(:event, groups: [@g1]))
  end

  def filter(params = {})
    Event::ApiFilter.new(group, params, today.year)
  end

  context 'filter param' do
    before do
      Fabricate(:event_date, event: event)
    end

    it 'sets start and end date from passed year' do
      expect(filter.start_date).to eq today.beginning_of_year.beginning_of_day
      expect(filter.end_date).to eq today.end_of_year.end_of_day
    end

    it 'lists events of descendant groups by default' do
      expect(filter.list_entries).to have(2).entries
    end

    it 'lists events of descendant groups for filter all' do
      expect(filter(filter: 'all').list_entries).to have(2).entries
    end

    it 'limits list to events of all non layer descendants' do
      expect(filter(filter: 'layer').list_entries).to have(1).entries
    end
  end

  context 'date params' do
    before do
      Event::Date.create(event: event, start_at: 5.days.ago, finish_at: 1.days.ago)
      Event::Date.create(event: event2, start_at: 5.days.from_now, finish_at: 1.years.from_now)
    end

    it 'lists upcoming events from now by default' do
      expect(filter.list_entries).to have(3).entries
    end

    it 'lists upcoming events for given start_date' do
      expect(filter(start_date: 2.days.ago).list_entries).to have(3).entries
    end

    it 'lists events from now to given end_date' do
      expect(filter(end_date: 4.days.from_now).list_entries).to have(1).entries
    end

    it 'lists events for given dates' do
      Event::Date.create(event: event, start_at: 11.years.from_now, finish_at: 12.years.from_now)
      expect(filter(start_date: 11.years.from_now,
                    end_date: 12.years.from_now).list_entries).to have(1).entries
    end

    it 'lists events on start date' do
      expect(filter(start_date: 5.days.ago,
                    end_date: 5.days.ago).list_entries).to have(1).entries
    end

    it 'lists events on finish date' do
      expect(filter(start_date: 1.days.ago,
                    end_date: 1.days.ago).list_entries).to have(1).entries
    end

    it 'does not raise error if dates invalid' do
      expect { filter(end_date: "inv'alid").list_entries }.not_to raise_error
      expect { filter(start_date: "inv'alid").list_entries }.not_to raise_error
    end

  end

end
