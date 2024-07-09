# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of hitobito and licensed under the
#  Affero General Public License version 3 or later. See the COPYING file at the top-level directory
#  or at https://github.com/hitobito/hitobito.

class Event::Qualifier::Calculator
  CourseRecord = Data.define(:qualification_kind_id,
    :qualification_date,
    :training_days,
    :summed_training_days)

  def initialize(courses, end_date, role: :participant, qualification_dates: {})
    @courses = courses
    @end_date = end_date
    @role = role
    @qualification_dates = qualification_dates
    @days = Hash.new(0)
  end

  def open_training_days(qualification_kind)
    return if qualification_kind.required_training_days.blank?

    summed_training_days = course_records_for(qualification_kind).last&.summed_training_days.to_f
    open_training_days = qualification_kind.required_training_days - summed_training_days
    open_training_days.negative? ? 0 : open_training_days
  end

  def start_at(qualification_kind)
    course_records_for(qualification_kind).find do |r|
      r.summed_training_days >= qualification_kind.required_training_days
    end&.qualification_date
  end

  def course_records
    @course_records ||= build_course_records.group_by(&:qualification_kind_id)
  end

  private

  def course_records_for(qualification_kind)
    course_records.fetch(qualification_kind.id, [])
  end

  def build_course_records
    sorted_courses_with_training_days.flat_map do |course|
      prolonging_qualification_kind_ids(course).map do |id, start_of_relevant_period|
        next if course.qualification_date < start_of_relevant_period

        @days[id] += course.training_days.to_f
        CourseRecord.new(id, course.qualification_date, course.training_days.to_f, @days[id])
      end
    end.compact
  end

  def prolonging_qualification_kind_ids(course)
    course.kind.event_kind_qualification_kinds
      .select(&:prolongation?)
      .select { |q| q.qualification_kind.required_training_days }
      .select { |q| q.role == @role.to_s }
      .map { |q| [q.qualification_kind_id, start_of_relevant_period(q.qualification_kind)] }
      .uniq
  end

  def qualification_date(qualification_kind_id, course)
    @qualification_dates[qualification_kind_id] || course.qualification_date
  end

  def start_of_relevant_period(qualification_kind)
    start_of_period = @end_date - qualification_kind.validity.years
    start_of_qualification = @qualification_dates[qualification_kind.id]
    start_of_qualification += 1.day if start_of_qualification
    [start_of_period, start_of_qualification].compact.max
  end

  def sorted_courses_with_training_days
    @courses
      .select { |course| course.training_days.to_f.positive? }.uniq
      .sort_by { |course| course.qualification_date }
      .reverse
      .uniq
  end
end
