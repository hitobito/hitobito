# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of hitobito and licensed under the
#  Affero General Public License version 3 or later. See the COPYING file at the top-level directory
#  or at https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Event::Qualifier::TrainingDaysCalculator do
  let(:sl) { qualification_kinds(:sl) }
  let(:gl) { qualification_kinds(:gl)  }
  let(:slk) { event_kinds(:slk) }
  let(:glk) { event_kinds(:glk) }
  let(:slkgl_pro) { event_kind_qualification_kinds(:slkgl_pro)  }

  let(:role) { :participant }
  let(:person) { people(:bottom_member) }

  let(:qualifying_participation) do
    create_course_participation(start_at: Date.today, training_days: 0.5, qualified: false)
  end

  let(:obj) { described_class.new(qualifying_participation, role, [gl, sl]) }

  before do
    sl.update!(required_training_days: 3, validity: 2)
    gl.update!(required_training_days: 2, validity: 1)
  end

  describe '#courses' do
    subject(:courses) { obj.courses }
    let(:start_at) { 1.month.ago }
    let(:last_valid_date) { gl.validity.years.ago.to_date }

    let!(:existing_participation) do
      create_course_participation(training_days: 1, start_at: start_at)
    end
    let(:existing_event_dates) { existing_participation.event.dates }

    it 'is present when kind role is participant' do
      slkgl_pro.update_columns(role: :participant)
      expect(courses).to be_present
    end

    it 'is empty when kind role is leader' do
      slkgl_pro.update_columns(role: :leader)
      expect(courses).to be_empty
    end

    it 'is empty when kind is precondition' do
      slkgl_pro.update_columns(category: :precondition)
      expect(courses).to be_empty
    end

    it 'is empty when kind is qualification' do
      slkgl_pro.update_columns(category: :qualification)
      expect(courses).to be_empty
    end

    it 'is empty when participation is not qualified' do
      existing_participation.update_columns(qualified: false)
      expect(courses).to be_empty
    end

    it 'is empty when course kind does not prolong qualification' do
      existing_participation.event.update!(kind: glk)
      expect(courses).to be_empty
    end

    it 'is present when course start_at is on last day of validity period' do
      existing_event_dates.first.update_columns(start_at: last_valid_date)
      expect(courses).to be_present
    end

    it 'is present when course start_at is on noon of last day of validity period' do
      existing_event_dates.first.update_columns(start_at: last_valid_date.noon)
      expect(courses).to be_present
    end

    it 'is present when last course finish_at is inside validity period' do
      existing_event_dates.first.update!(start_at: last_valid_date - 1.week)
      existing_event_dates.create(finish_at: last_valid_date.end_of_day)
      expect(courses).to be_present
    end

    it 'is blank when last course finish_at is just outside validity period' do
      existing_event_dates.first.update!(start_at: last_valid_date - 1.week)
      existing_event_dates.create(finish_at: last_valid_date.end_of_day - 1.second)
      expect(courses).to be_present
    end

    it 'has multiple entries if multiple courses match single qualification kind' do
      create_course_participation(start_at: 10.months.ago)
      expect(courses).to have(2).items
    end

    it 'has multiple entries if multiple courses match various qualification kinds' do
      create_course_participation(kind: glk, start_at: 10.months.ago)
      create_event_kind_qualification_kind(glk, sl)
      expect(courses).to have(2).items
    end
  end

  describe '#course_records' do
    it 'is empty when no courses are found and qualifying course has no training days' do
      qualifying_participation.event.update!(training_days: 0)
      expect(obj.course_records).to be_empty
    end

    it 'includes a record for qualifying event if it has any positive amount of training_days' do
      expect(obj.course_records.keys).to eq [gl.id]
      records = obj.course_records[gl.id]
      expect(records).to have(1).items
      expect(records[0].qualification_kind_id).to eq gl.id
      expect(records[0].qualification_date).to eq Date.today
      expect(records[0].training_days).to eq 0.5
      expect(records[0].summed_training_days).to eq 0.5
    end

    it 'does not include qualifying twice even if participation is qualieid' do
      qualifying_participation.update!(qualified: true)
      expect(obj.course_records.keys).to eq [gl.id]
      records = obj.course_records[gl.id]
      expect(records).to have(1).items
    end

    it 'creates record for each course with qualifying date, training days and summed total' do
      create_course_participation(training_days: 2.5, start_at: 2.months.ago)
      create_course_participation(training_days: 0.5, start_at: 1.week.ago)

      expect(obj.course_records.keys).to eq [gl.id]

      records = obj.course_records[gl.id]
      expect(records).to have(3).items

      expect(records[0].qualification_date).to eq Date.today
      expect(records[0].training_days).to eq 0.5
      expect(records[0].summed_training_days).to eq 0.5

      expect(records[1].qualification_date).to eq 1.week.ago.to_date
      expect(records[1].training_days).to eq 0.5
      expect(records[1].summed_training_days).to eq 1

      expect(records[2].qualification_date).to eq 2.months.ago.to_date
      expect(records[2].training_days).to eq 2.5
      expect(records[2].summed_training_days).to eq 3.5
    end

    it 'populates for multiple qualification kinds from single course' do
      create_event_kind_qualification_kind(slk, sl)
      expect(obj.course_records.keys).to match_array([gl.id, sl.id])
    end

    it 'populates for multiple qualification kinds from multiple courses' do
      create_course_participation(kind: glk, training_days: 3, start_at: 1.months.ago)
      create_event_kind_qualification_kind(glk, sl)

      expect(obj.courses).to have(1).item
      expect(obj.course_records.keys).to eq([gl.id, sl.id])
    end

    it 'ignores qualification kinds from other course when outside validity period' do
      gl.update(validity: 2)
      sl.update(validity: 1)

      create_course_participation(kind: glk, training_days: 3, start_at: 23.months.ago)
      create_event_kind_qualification_kind(glk, gl)
      create_event_kind_qualification_kind(glk, sl)

      expect(obj.courses).to have(1).item
      expect(obj.course_records.keys).to eq([gl.id])
    end

    it 'always includes qualification kinds of qualifying course as validity period is relative to qualifying course' do
      qualifying_participation.event.dates.first.update_columns(start_at: 10.years.ago)
      create_event_kind_qualification_kind(slk, sl)

      expect(obj.course_records.keys).to eq([gl.id, sl.id])
    end
  end

  describe '#start_at' do
    it 'is nil when we have no courses' do
      expect(obj.start_at(gl)).to be_nil
    end

    it 'is nil when required_training_days are not reached' do
      create_course_participation(training_days: 0.5, start_at: 1.month.ago)
      create_course_participation(training_days: 0.5, start_at: 1.week.ago)
      expect(obj.start_at(gl)).to be_nil
    end

    it 'is present when required_training_days are reached' do
      create_course_participation(training_days: 2, start_at: 1.month.ago)
      expect(obj.start_at(gl)).to eq 1.month.ago.to_date
    end

    it 'equals start_at of first course that matches or exceeds training days' do
      create_course_participation(training_days: 1, start_at: 3.months.ago)
      create_course_participation(training_days: 1, start_at: 2.months.ago)
      create_course_participation(training_days: 1, start_at: 1.months.ago)
      expect(obj.start_at(gl)).to eq 2.months.ago.to_date
    end

    it 'is nil when we pass a different qualification_kind' do
      create_course_participation(training_days: 2, start_at: 1.month.ago)
      expect(obj.start_at(sl)).to be_nil
    end
  end

  def create_course_participation(kind: slk, qualified: true, training_days: nil, start_at:)
    course = Fabricate.build(:course, kind: kind, training_days: training_days)
    course.dates.build(start_at: start_at)
    course.save!
    Fabricate(:event_participation, event: course, person: person, qualified: qualified)
  end

  def create_event_kind_qualification_kind(event_kind, qualification_kind)
    Event::KindQualificationKind.create!(
      event_kind: event_kind,
      qualification_kind: qualification_kind,
      category: :prolongation,
      role: role
    )
  end
end
