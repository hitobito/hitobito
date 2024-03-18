# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of hitobito and licensed under the
#  Affero General Public License version 3 or later. See the COPYING file at the top-level directory
#  or at https://github.com/hitobito/hitobito.

class Event::Qualifier::TrainingDaysCalculator

  CourseRecord = Data.define(:qualification_kind_id,
                             :qualification_date,
                             :training_days,
                             :summed_training_days)


  def initialize(participation, role, qualification_kinds)
    @person = participation.person
    @event = participation.event
    @qualification_kinds = qualification_kinds.select(&:required_training_days)
    @role = role
  end

  def start_at(qualification_kind)
    records = course_records.fetch(qualification_kind.id, [])
    records.find do |r|
      r.summed_training_days >= qualification_kind.required_training_days
    end&.qualification_date
  end

  def course_records
    @course_records ||= build_course_records.group_by(&:qualification_kind_id)
  end

  def courses
    @courses ||= load_courses
  end

  private

  def build_course_records
    days = Hash.new(0)
    courses_with_training_days.flat_map do |course|
      prolonging_qualification_kind_ids(course).map do |id, start_of_validity_period|
        next if course.qualification_date < start_of_validity_period

        days[id] += course.training_days.to_f
        CourseRecord.new(id, course.qualification_date, course.training_days.to_f, days[id])
      end
    end.compact
  end

  def load_courses
    Event::Course
      .between(earliest_qualification_date, qualification_date)
      .includes(kind: { event_kind_qualification_kinds: :qualification_kind })
      .joins(:participations, kind: { event_kind_qualification_kinds: :qualification_kind })
      .where(event_participations: { qualified: true, person: @person })
      .where(event_kind_qualification_kinds: {
        qualification_kind_id: @qualification_kinds,
        category: :prolongation,
        role: @role,
      })
      .order('event_dates.start_at DESC')
      .distinct
  end

  def courses_with_training_days
    ([@event] + courses).select { |event| event.training_days.to_f.positive? }.uniq
  end

  def prolonging_qualification_kind_ids(course)
    course.kind.event_kind_qualification_kinds
      .select(&:prolongation?)
      .select { |q| q.qualification_kind.required_training_days }
      .select { |q| q.role == @role.to_s }
      .map { |q| [q.qualification_kind_id, start_of_validity_period(q.qualification_kind)] }
      .uniq
  end

  def qualification_date
    @event.qualification_date
  end

  def start_of_validity_period(qualification_kind)
    qualification_date - qualification_kind.validity.years
  end

  def earliest_qualification_date
    start_of_validity_period(@qualification_kinds.max_by(&:validity))
  end
end
