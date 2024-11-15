# == Schema Information
#
# Table name: calendars
#
#  id          :bigint           not null, primary key
#  description :text
#  name        :string           not null
#  token       :string           not null
#  group_id    :bigint           not null
#
# Indexes
#
#  index_calendars_on_group_id  (group_id)
#

require "spec_helper"

describe Calendar do
  let(:group) { groups(:top_group) }
  let(:calendar) { Fabricate(:calendar, group: group) }

  context "deleting" do
    let(:tag) { Fabricate(:tag) }
    let(:subgroup) { group.children.create!(name: "subgroup", type: Group::TopGroup.sti_name) }
    let!(:calendar_group) { Fabricate(:calendar_group, excluded: false, calendar: calendar, group: subgroup) }
    let!(:calendar_tag) { Fabricate(:calendar_tag, tag: tag, calendar: calendar, excluded: false) }

    it "deletes calendar tag when the referenced tag is destroyed" do
      expect { tag.destroy! }.to change { CalendarTag.count }.by(-1)
      expect(Calendar.find(calendar.id).name).to eq calendar.name
    end

    it "deletes calendar group when the referenced group is destroyed" do
      expect { subgroup.destroy! }.to change { CalendarGroup.count }.by(-1)
      expect(Calendar.find(calendar.id).name).to eq calendar.name
    end

    it "deletes calendar when the last included group is destroyed" do
      calendar.included_calendar_groups.first.destroy!
      expect { subgroup.destroy! }.to change { CalendarGroup.count }.by(-1)
      expect { Calendar.find(calendar.id) }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
