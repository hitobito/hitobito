# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of hitobito and licensed under the
#  Affero General Public License version 3 or later. See the COPYING file at the top-level directory
#  or at https://github.com/hitobito/hitobito.

require "spec_helper"

describe Event::Qualifier::Calculator do
  let(:gl) { qualification_kinds(:gl) }
  let(:slk) { event_kinds(:slk) }

  let(:role) { :participant }
  let(:person) { Fabricat.build(:person) }

  let(:begin_of_period) { gl.validity.years.ago.to_date }
  let(:qualification_dates) { {} }

  let(:obj) do
    described_class.new(@courses.to_a.shuffle, Time.zone.today,
      qualification_dates: qualification_dates)
  end

  before do
    @courses = []
    gl.update!(required_training_days: 2, validity: 1)
  end

  describe "#course_records" do
    subject(:gl_records) { obj.course_records[gl.id] }

    subject(:course_records) { obj.course_records }

    it "builds record for course" do
      add_course(training_days: 0.5, start_at: 1.week.ago)

      expect(gl_records).to have(1).item
      expect(gl_records[0].qualification_date).to eq 1.week.ago.to_date
      expect(gl_records[0].training_days).to eq 0.5
      expect(gl_records[0].summed_training_days).to eq 0.5
    end

    it "ignores duplicate courses" do
      add_course(training_days: 0.5, start_at: 1.week.ago)
      @courses += @courses
      expect(gl_records).to have(1).item
    end

    it "builds records for multiple courses summing up total training days" do
      add_course(training_days: 2.5, start_at: 2.months.ago)
      add_course(training_days: 0.5, start_at: 1.week.ago)

      expect(gl_records).to have(2).items

      expect(gl_records[0].qualification_date).to eq 1.week.ago.to_date
      expect(gl_records[0].training_days).to eq 0.5
      expect(gl_records[0].summed_training_days).to eq 0.5

      expect(gl_records[1].qualification_date).to eq 2.months.ago.to_date
      expect(gl_records[1].training_days).to eq 2.5
      expect(gl_records[1].summed_training_days).to eq 3
    end

    it "accepts courses start on same day" do
      add_course(training_days: 0.5, start_at: 1.week.ago)
      add_course(training_days: 0.5, start_at: 1.week.ago)
      expect(gl_records).to have(2).items
    end

    describe "relevant period" do
      it "ignores course starting outside of relevant period" do
        add_course(training_days: 0.5, start_at: begin_of_period - 1.day)
        expect(gl_records).to be_nil
      end

      it "accepts course starting on second day of relevant period" do
        add_course(training_days: 0.5, start_at: begin_of_period)
        expect(gl_records).to be_present
      end

      it "accepts course finishing on second day of relevant period" do
        add_course(training_days: 0.5, start_at: begin_of_period - 1.day,
          finish_at: begin_of_period)
        expect(gl_records).to be_present
      end

      describe "qualification specific dates" do
        it "accepts course if occuring after qualification date at start of relevant period" do
          qualification_dates[gl.id] = begin_of_period - 1.day
          add_course(training_days: 0.5, start_at: begin_of_period)
          expect(gl_records).to be_present
        end

        it "ignores course if occuring on qualification date at start of relevant period" do
          qualification_dates[gl.id] = begin_of_period
          add_course(training_days: 0.5, start_at: begin_of_period)
          expect(gl_records).to be_nil
        end

        it "accepts course if occuring after qualification date in relevant period" do
          qualification_dates[gl.id] = 300.days.ago.to_date
          add_course(training_days: 0.5, start_at: 299.days.ago.to_date)
          expect(gl_records).to be_present
        end

        it "ignores course if occuring on qualification date in relevant period" do
          qualification_dates[gl.id] = 300.days.ago.to_date
          add_course(training_days: 0.5, start_at: 300.days.ago.to_date)
          expect(gl_records).to be_nil
        end

        it "ignores course if occuring before qualification date in relevant period" do
          qualification_dates[gl.id] = 300.days.ago.to_date
          add_course(training_days: 0.5, start_at: 301.days.ago.to_date)
          expect(gl_records).to be_nil
        end
      end
    end

    context "mulitple qualification kinds" do
      let(:sl) { qualification_kinds(:sl) }
      let(:glk) { event_kinds(:glk) }

      before do
        sl.update!(required_training_days: 3, validity: 2)
        add_course(training_days: 0.5, start_at: 1.week.ago)
      end

      it "populates for multiple qualification kinds from single course" do
        create_event_kind_qualification_kind(slk, sl)
        expect(course_records.keys).to match_array([gl.id, sl.id])
      end

      it "populates for multiple qualification kinds from multiple courses" do
        create_event_kind_qualification_kind(glk, sl)
        add_course(kind: glk, training_days: 3, start_at: 1.month.ago)
        expect(course_records.keys).to eq([gl.id, sl.id])
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
  end

  describe "#start_at" do
    it "is nil when we have no courses" do
      expect(obj.start_at(gl)).to be_nil
    end

    it "is nil when required_training_days are not reached" do
      add_course(training_days: 0.5, start_at: 1.month.ago)
      add_course(training_days: 0.5, start_at: 1.week.ago)
      expect(obj.start_at(gl)).to be_nil
    end

    it "is present when required_training_days are reached" do
      add_course(training_days: 2, start_at: 1.month.ago)
      expect(obj.start_at(gl)).to eq 1.month.ago.to_date
    end

    it "equals start_at of first course that matches or exceeds training days" do
      add_course(training_days: 1, start_at: 3.months.ago)
      add_course(training_days: 1, start_at: 2.months.ago)
      add_course(training_days: 1, start_at: 1.month.ago)
      expect(obj.start_at(gl)).to eq 2.months.ago.to_date
    end

    it "is nil when we pass a different qualification_kind" do
      add_course(training_days: 2, start_at: 1.month.ago)
      expect(obj.start_at(qualification_kinds(:sl))).to be_nil
    end
  end

  describe "#open_training_days" do
    subject(:open_training_days) { obj.open_training_days(gl) }

    it "is nil when qualification kind has no required training days" do
      gl.update(required_training_days: nil)
      expect(open_training_days).to be_nil
    end

    it "is full amount without courses" do
      expect(open_training_days).to eq 2
    end

    it "is full amount when course is outside validity period" do
      add_course(training_days: 2, start_at: begin_of_period - 1.day)
      expect(open_training_days).to eq 2
    end

    it "subtracts single course training_days when course is in validity period" do
      add_course(training_days: 0.5, start_at: begin_of_period)
      expect(open_training_days).to eq 1.5
    end

    it "substracts all matching courses from required training days" do
      add_course(training_days: 0.5, start_at: begin_of_period)
      add_course(training_days: 0.5, start_at: begin_of_period + 1.week)
      add_course(training_days: 0.5, start_at: begin_of_period + 2.weeks)
      expect(open_training_days).to eq 0.5
    end

    it "caps out at zero if required training days are exceeded" do
      add_course(training_days: 0.5, start_at: begin_of_period)
      add_course(training_days: 2.5, start_at: begin_of_period + 1.week)
      expect(open_training_days).to eq 0
    end
  end

  def add_course(start_at:, kind: slk, qualified: true, training_days: nil, finish_at: nil)
    course = Fabricate.build(:course, kind: kind, training_days: training_days)
    course.dates.build(start_at: start_at, finish_at: finish_at)
    course.tap { @courses += [course] }
  end
end
