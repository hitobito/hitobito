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
        CourseRecord.new(id, course.qualification_date, course.training_days.to_f,
          @days[id].round(2)) # avoid floating point imprecision
      end
    end.compact
  end

  def prolonging_qualification_kind_ids(course)
    prolonging_qualification_kinds(course).uniq.map do |q|
      [q.qualification_kind_id, start_of_relevant_period(q.qualification_kind)]
    end
  end

  def prolonging_qualification_kinds(course)
    course.kind.event_kind_qualification_kinds.select do |q|
      q.prolongation? && q.qualification_kind.required_training_days && q.role == @role.to_s
    end
  end

  def start_of_relevant_period(qualification_kind)
    start_of_period = (@end_date - qualification_kind.validity.years).beginning_of_year
    start_of_qualification = @qualification_dates[qualification_kind.id]
    if start_of_qualification
      # @qualification_dates are only present for open_training_days calculation,
      # but not for start_at dates calculation.
      # Additional training days in the year of the qualification start date
      # are irrelevant for the open_training_days, because they do not prolong
      # the qualification any longer. Hence only training days from the beginning
      # of the following year are relevant.
      [start_of_period, start_of_qualification.end_of_year + 1.day].max
    else
      start_of_period
    end
  end

  def sorted_courses_with_training_days
    @courses
      .uniq
      .select { |course| course.training_days.to_f.positive? }
      .sort_by { |course| course.qualification_date }
      .reverse
  end
end
