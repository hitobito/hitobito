# encoding: utf-8

#  Copyright (c) 2022, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Calendar do

  let(:group)    { groups(:top_group) }
  let(:calendar) { Fabricate(:calendar, group: group) }

  context 'deleting' do
    let(:tag) { Fabricate(:tag) }
    let(:subgroup) { group.children.create!(name: 'subgroup', type: Group::TopGroup.sti_name) }
    let!(:calendar_group) { Fabricate(:calendar_group, excluded: false, calendar: calendar, group: subgroup) }
    let!(:calendar_tag) { Fabricate(:calendar_tag, tag: tag, calendar: calendar, excluded: false) }

    it 'deletes calendar tag when the referenced tag is destroyed' do
      expect { tag.destroy! }.to change { CalendarTag.count }.by -1
      expect(Calendar.find(calendar.id).name).to eq calendar.name
    end

    it 'deletes calendar group when the referenced group is destroyed' do
      expect { subgroup.destroy! }.to change { CalendarGroup.count }.by -1
      expect(Calendar.find(calendar.id).name).to eq calendar.name
    end

    it 'deletes calendar when the last included group is destroyed' do
      calendar.included_calendar_groups.first.destroy!
      expect { subgroup.destroy! }.to change { CalendarGroup.count }.by -1
      expect { Calendar.find(calendar.id) }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

end
