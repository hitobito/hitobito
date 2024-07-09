# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of hitobito and licensed under the
#  Affero General Public License version 3 or later. See the COPYING file at the top-level directory
#  or at https://github.com/hitobito/hitobito.

require "spec_helper"

describe Event::TrainingDays::CoursesLoader do
  let(:person) { people(:bottom_member) }
  let(:slk) { event_kinds(:slk) }
  let(:sl) { qualification_kinds(:sl) }
  let(:gl) { qualification_kinds(:gl) }

  let(:role) { :participant }

  let(:end_date) { 1.month.ago }
  let(:start_date) { gl.validity.years.ago.to_date }

  subject(:courses) { described_class.new(person.id, role, [gl.id, sl.id], start_date, end_date).load }

  before { gl.update!(required_training_days: 2, validity: 1) }

  let!(:existing_participation) do
    create_course_participation(training_days: 1, start_at: start_date + 1.day)
  end

  describe "qualification kind filtering" do
    let(:slkgl_pro) { event_kind_qualification_kinds(:slkgl_pro) }

    it "is present when kind role is participant" do
      slkgl_pro.update_columns(role: :participant)
      expect(courses).to be_present
    end

    it "is empty when kind role is leader" do
      slkgl_pro.update_columns(role: :leader)
      expect(courses).to be_empty
    end

    it "is empty when kind is precondition" do
      slkgl_pro.update_columns(category: :precondition)
      expect(courses).to be_empty
    end

    it "is empty when kind is qualification" do
      slkgl_pro.update_columns(category: :qualification)
      expect(courses).to be_empty
    end
  end

  describe "qualification filtering" do
    it "is empty when participation is not qualified" do
      existing_participation.update_columns(qualified: false)
      expect(courses).to be_empty
    end
  end

  describe "event dates filtering" do
    let(:existing_event_dates) { existing_participation.event.dates }

    it "is present when course start_at is on last day of validity period" do
      existing_event_dates.first.update_columns(start_at: end_date)
      expect(courses).to be_present
    end

    it "is present when course start_at is at noon of last day of validity period" do
      travel_to(Time.zone.now.noon - 1.hour)
      existing_event_dates.first.update_columns(start_at: end_date.noon)
      expect(courses).to be_present
    end

    it "is present when last course finish_at is inside validity period" do
      existing_event_dates.first.update!(start_at: end_date - 1.week)
      existing_event_dates.create(finish_at: end_date.end_of_day)
      expect(courses).to be_present
    end

    it "is blank when last course finish_at is just outside validity period" do
      existing_event_dates.first.update!(start_at: end_date - 1.week)
      existing_event_dates.create(finish_at: end_date.end_of_day - 1.second)
      expect(courses).to be_present
    end
  end

  describe "event kind filtering" do
    let(:glk) { event_kinds(:glk) }

    before { sl.update!(required_training_days: 3, validity: 2) }

    it "is empty when course kind does not prolong qualification" do
      existing_participation.event.update!(kind: glk)
      expect(courses).to be_empty
    end
    it "has multiple entries if multiple courses match single qualification kind" do
      create_course_participation(start_at: 10.months.ago)
      expect(courses).to have(2).items
    end

    it "has multiple entries if multiple courses match various qualification kinds" do
      create_course_participation(kind: glk, start_at: 10.months.ago)
      create_event_kind_qualification_kind(glk, sl)
      expect(courses).to have(2).items
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

  def create_course_participation(start_at:, kind: slk, qualified: true, training_days: nil)
    course = Fabricate.build(:course, kind: kind, training_days: training_days)
    course.dates.build(start_at: start_at)
    course.save!
    Fabricate(:event_participation, event: course, person: person, qualified: qualified)
  end
end
