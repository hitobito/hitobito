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

  let(:end_date) { Time.zone.today }
  let(:begin_of_period) { gl.validity.years.ago.to_date.at_beginning_of_year }
  let(:qualification_dates) { {} }

  let(:calculator) do
    described_class.new(
      @courses.to_a.shuffle,
      end_date,
      qualification_dates: qualification_dates
    )
  end

  before do
    @courses = []
    gl.update!(required_training_days: 2, validity: 1)
  end

  describe "#course_records" do
    subject(:gl_records) { calculator.course_records[gl.id] }

    subject(:course_records) { calculator.course_records }

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

        it "accepts course if occuring after qualification year in relevant period" do
          qualification_dates[gl.id] = 1.year.ago.to_date
          add_course(training_days: 0.5, start_at: 1.year.ago.to_date.end_of_year + 1.day)
          expect(gl_records).to be_present
        end

        it "ignores course if occuring in qualification year in relevant period" do
          skip if Date.current.day == 31 && Date.current.month == 12

          qualification_dates[gl.id] = 1.year.ago.to_date
          add_course(training_days: 0.5, start_at: 1.year.ago.to_date + 1.day)
          expect(gl_records).to be_nil
        end

        it "ignores course if occuring on qualification date in relevant period" do
          qualification_dates[gl.id] = 1.year.ago.to_date
          add_course(training_days: 0.5, start_at: 1.year.ago.to_date)
          expect(gl_records).to be_nil
        end

        it "ignores course if occuring before qualification date in relevant period" do
          qualification_dates[gl.id] = 1.year.ago.to_date
          add_course(training_days: 0.5, start_at: 1.year.ago.to_date - 1.day)
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
      expect(calculator.start_at(gl)).to be_nil
    end

    it "is nil when required_training_days are not reached" do
      add_course(training_days: 0.5, start_at: 1.month.ago)
      add_course(training_days: 0.5, start_at: 1.week.ago)
      expect(calculator.start_at(gl)).to be_nil
    end

    it "is present when required_training_days are reached" do
      add_course(training_days: 2, start_at: 1.month.ago)
      expect(calculator.start_at(gl)).to eq 1.month.ago.to_date
    end

    it "equals start_at of first course that matches or exceeds training days" do
      add_course(training_days: 1, start_at: 3.months.ago)
      add_course(training_days: 1, start_at: 2.months.ago)
      add_course(training_days: 1, start_at: 1.month.ago)
      expect(calculator.start_at(gl)).to eq 2.months.ago.to_date
    end

    it "equals start_at of first course that matches or exceeds training days with floating point" do
      gl.update!(required_training_days: 3)
      add_course(training_days: 0.3, start_at: 7.months.ago)
      add_course(training_days: 0.4, start_at: 6.months.ago)
      add_course(training_days: 0.3, start_at: 5.months.ago)
      add_course(training_days: 0.7, start_at: 4.months.ago)
      add_course(training_days: 0.7, start_at: 3.months.ago)
      add_course(training_days: 0.2, start_at: 2.months.ago)
      add_course(training_days: 0.7, start_at: 1.month.ago)
      expect(calculator.start_at(gl)).to eq 6.months.ago.to_date
    end

    it "is nil when we pass a different qualification_kind" do
      add_course(training_days: 2, start_at: 1.month.ago)
      expect(calculator.start_at(qualification_kinds(:sl))).to be_nil
    end
  end

  describe "#open_training_days" do
    subject(:open_training_days) { calculator.open_training_days(gl) }

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

    # based on SAC definitions as described in
    # https://github.com/hitobito/hitobito_sac_cas/issues/1645
    context "longer validity and reactivatability" do
      before do
        gl.update!(required_training_days: 3, validity: 6, reactivateable: 4)
        add_course(training_days: 7, start_at: "2010-08-21")
        @qualification_dates = {gl.id => Date.new(2010, 8, 21)}
      end

      it "with training 2012 (1 day)" do
        expect(open_days(2012, 2)).to eq(3)
        add_course(training_days: 1, start_at: "2012-03-08")
        expect(open_days(2012, 4)).to eq(2)
        expect(open_days(2018, 12)).to eq(2)
        expect(open_days(2019, 1)).to eq(3)
        expect(open_days(2020, 12)).to eq(3)
      end

      it "with training 2012 (1 day) and 2014 (1 day)" do
        add_course(training_days: 1, start_at: "2012-03-08")
        add_course(training_days: 1, start_at: "2014-05-08")
        expect(open_days(2014, 6)).to eq(1)
        expect(open_days(2018, 12)).to eq(1)
        expect(open_days(2019, 1)).to eq(2)
      end

      it "with training 2012 (1 day), 2014 (1 day) and 2016 (1 day)" do
        add_course(training_days: 1, start_at: "2012-03-08")
        add_course(training_days: 1, start_at: "2014-05-08")
        add_course(training_days: 1, start_at: "2016-07-08")
        @qualification_dates[gl.id] = Date.new(2012, 3, 8)
        expect(open_days(2016, 8)).to eq(1)
        expect(open_days(2020, 12)).to eq(1)
        expect(open_days(2021, 1)).to eq(2)
      end

      it "with training 2012 (1 day), 2014 (1 day) and 2016 (2 days)" do
        add_course(training_days: 1, start_at: "2012-03-08")
        add_course(training_days: 1, start_at: "2014-05-08")
        add_course(training_days: 2, start_at: "2016-07-08")
        @qualification_dates[gl.id] = Date.new(2014, 5, 8)
        expect(open_days(2016, 8)).to eq(1)
        expect(open_days(2022, 12)).to eq(1)
        expect(open_days(2023, 1)).to eq(3)
      end

      it "with training 2012 (1 day), 2014 (1 day) and 2016 (3 days)" do
        add_course(training_days: 1, start_at: "2012-03-08")
        add_course(training_days: 1, start_at: "2014-05-08")
        add_course(training_days: 3, start_at: "2016-07-08")
        @qualification_dates[gl.id] = Date.new(2016, 7, 8)
        expect(open_days(2016, 8)).to eq(3)
        expect(open_days(2026, 12)).to eq(3)
      end

      it "with training 2012 (1 day), 2014 (1 day) and 2018 (1 day)" do
        add_course(training_days: 1, start_at: "2012-03-08")
        add_course(training_days: 1, start_at: "2014-05-08")
        add_course(training_days: 1, start_at: "2018-09-08")
        @qualification_dates[gl.id] = Date.new(2012, 3, 8)
        expect(open_days(2018, 10)).to eq(1)
        expect(open_days(2020, 12)).to eq(1)
        expect(open_days(2021, 1)).to eq(2)
      end

      it "with training 2012 (1 day), 2014 (1 day) and 2019 (1 day)" do
        add_course(training_days: 1, start_at: "2012-03-08")
        add_course(training_days: 1, start_at: "2014-05-08")
        expect(open_days(2019, 9)).to eq(2)
        add_course(training_days: 1, start_at: "2019-09-08")
        expect(open_days(2019, 10)).to eq(1)
      end

      it "with training 2012 (1 day), 2014 (1 day) and 2019 (2 days)" do
        add_course(training_days: 1, start_at: "2012-03-08")
        add_course(training_days: 1, start_at: "2014-05-08")
        expect(open_days(2019, 9)).to eq(2)
        add_course(training_days: 2, start_at: "2019-09-08")
        @qualification_dates[gl.id] = Date.new(2014, 5, 8)
        expect(open_days(2019, 10)).to eq(1)
        expect(open_days(2024, 12)).to eq(1)
      end

      it "with training 2012 (3 days)" do
        add_course(training_days: 3, start_at: "2012-03-08")
        @qualification_dates[gl.id] = Date.new(2012, 3, 8)
        expect(open_days(2012, 4)).to eq(3)
        expect(open_days(2022, 12)).to eq(3)
      end

      it "with training 2018 (3 days)" do
        add_course(training_days: 3, start_at: "2018-05-08")
        @qualification_dates[gl.id] = Date.new(2018, 5, 8)
        expect(open_days(2018, 6)).to eq(3)
        expect(open_days(2028, 12)).to eq(3)
      end

      it "with training 2012 (1 days), 2014 (1 day), 2016 (2 days), 2018 (1 day), 2019 (1 day)" do
        add_course(training_days: 1, start_at: "2012-03-08")
        add_course(training_days: 1, start_at: "2014-05-08")
        add_course(training_days: 2, start_at: "2016-07-08")
        @qualification_dates[gl.id] = Date.new(2014, 5, 8)
        expect(open_days(2018, 8)).to eq(1)
        add_course(training_days: 1, start_at: "2018-09-08")
        @qualification_dates[gl.id] = Date.new(2016, 7, 8)
        expect(open_days(2018, 10)).to eq(2)
        add_course(training_days: 1, start_at: "2019-10-08")
        expect(open_days(2019, 11)).to eq(1)
        expect(open_days(2024, 12)).to eq(1)
        expect(open_days(2025, 1)).to eq(2)
        expect(open_days(2026, 1)).to eq(3)
      end

      it "with training 2012 (1 days), 2014 (1 day), 2016 (2 days), 2018 (1 day), 2019 (2 days)" do
        add_course(training_days: 1, start_at: "2012-03-08")
        add_course(training_days: 1, start_at: "2014-05-08")
        add_course(training_days: 2, start_at: "2016-07-08")
        add_course(training_days: 1, start_at: "2018-09-08")
        add_course(training_days: 2, start_at: "2019-10-08")
        @qualification_dates[gl.id] = Date.new(2018, 9, 8)
        expect(open_days(2019, 11)).to eq(1)
        expect(open_days(2025, 1)).to eq(1)
        expect(open_days(2026, 1)).to eq(3)
      end

      it "with training 2012 (1 days), 2014 (1 day), 2016 (2 days), 2018 (2 days), 2019 (1 day)" do
        add_course(training_days: 1, start_at: "2012-03-08")
        add_course(training_days: 1, start_at: "2014-05-08")
        add_course(training_days: 2, start_at: "2016-07-08")
        add_course(training_days: 2, start_at: "2018-09-08")
        @qualification_dates[gl.id] = Date.new(2016, 7, 8)
        expect(open_days(2018, 10)).to eq(1)
        add_course(training_days: 1, start_at: "2019-10-08")
        @qualification_dates[gl.id] = Date.new(2018, 9, 8)
        expect(open_days(2019, 11)).to eq(2)
        expect(open_days(2025, 12)).to eq(2)
        expect(open_days(2026, 1)).to eq(3)
      end

      it "with training 2016 (3 days) and 2018 (1 day)" do
        add_course(training_days: 3, start_at: "2016-07-08")
        @qualification_dates[gl.id] = Date.new(2016, 7, 8)
        expect(open_days(2018, 7)).to eq(3)
        add_course(training_days: 1, start_at: "2018-07-08")
        expect(open_days(2018, 8)).to eq(2)
        expect(open_days(2024, 12)).to eq(2)
        expect(open_days(2025, 1)).to eq(3)
      end

      it "with training 2016 (3 days), 2018 (1 day) and 2020 (1 day)" do
        add_course(training_days: 3, start_at: "2016-07-08")
        @qualification_dates[gl.id] = Date.new(2016, 7, 8)
        expect(open_days(2018, 7)).to eq(3)
        add_course(training_days: 1, start_at: "2018-07-08")
        add_course(training_days: 1, start_at: "2020-11-08")
        expect(open_days(2020, 12)).to eq(1)
        expect(open_days(2024, 12)).to eq(1)
        expect(open_days(2025, 1)).to eq(2)
      end

      it "with training 2011 (0.5), 2012 (0.5), 2013 (0.5), 2014 (0.5), 2015 (0.5), 2016 (0.5 day)" do
        expect(open_days(2011, 2)).to eq(3)
        add_course(training_days: 0.5, start_at: "2011-02-08")
        expect(open_days(2011, 3)).to eq(2.5)
        add_course(training_days: 0.5, start_at: "2012-03-08")
        expect(open_days(2012, 4)).to eq(2)
        add_course(training_days: 0.5, start_at: "2013-04-08")
        expect(open_days(2013, 5)).to eq(1.5)
        add_course(training_days: 0.5, start_at: "2014-05-08")
        expect(open_days(2014, 6)).to eq(1)
        add_course(training_days: 0.5, start_at: "2015-06-08")
        expect(open_days(2015, 7)).to eq(0.5)
        add_course(training_days: 0.5, start_at: "2016-07-08")
        @qualification_dates[gl.id] = Date.new(2011, 2, 8)
        expect(open_days(2016, 8)).to eq(0.5)
        expect(open_days(2019, 1)).to eq(1)
        expect(open_days(2020, 1)).to eq(1.5)
        expect(open_days(2021, 1)).to eq(2)
      end

      it "with training 2012 (2), 2012 (1), 2014 (2)" do
        expect(open_days(2011, 2)).to eq(3)
        add_course(training_days: 2, start_at: "2012-02-08")
        expect(open_days(2012, 3)).to eq(1)
        add_course(training_days: 1, start_at: "2012-12-31")
        @qualification_dates[gl.id] = Date.new(2012, 2, 8)
        # because quali is valid until 2018, additional days in 2012
        # would not prolong quali (it would still be valid until 2018),
        # hence there are 3 open days
        expect(open_days(2012, 11)).to eq(3)
        add_course(training_days: 2, start_at: "2014-04-08")
        @qualification_dates[gl.id] = Date.new(2012, 12, 31)
        expect(open_days(2014, 5)).to eq(1)
        expect(open_days(2020, 12)).to eq(1)
        expect(open_days(2021, 1)).to eq(3)
      end

      def open_days(year, month)
        date = Date.new(year, month, 1)
        calculator = described_class.new(@courses, date, qualification_dates: @qualification_dates)
        calculator.open_training_days(gl)
      end
    end
  end

  def add_course(start_at:, kind: slk, qualified: true, training_days: nil, finish_at: nil)
    course = Fabricate.build(:course, kind: kind, training_days: training_days)
    course.dates.build(start_at: start_at, finish_at: finish_at)
    @courses += [course]
    course
  end
end
