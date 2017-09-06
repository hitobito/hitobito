# encoding: utf-8

#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Event::PreconditionChecker

  extend Forwardable
  include Translatable

  def_delegator 'course.kind', :minimum_age, :course_minimum_age
  def_delegator 'errors', :empty?, :valid?
  attr_reader :course, :person, :errors

  def initialize(course, person)
    @course = course
    @person = person
    @errors = []
    validate
  end

  def validate
    validate_minimum_age if course_minimum_age

    validate_qualifications
  end

  def errors_text
    text = []
    if errors.present?
      text << translate(:preconditions_not_fulfilled)
      text << birthday_error_text if errors.delete(:birthday)
      text << some_qualifications_error_text if errors.delete(:some_qualifications)
      text << qualifications_error_text if errors.present?
    end
    text
  end

  private

  def validate_minimum_age
    errors << :birthday unless person.birthday && old_enough?
  end

  def validate_qualifications
    grouped_ids = course.kind.grouped_qualification_kind_ids('precondition', 'participant')
    if grouped_ids.size == 1
      validate_simple_qualifications(grouped_ids.first)
    elsif grouped_ids.size > 1
      validate_grouped_qualifications(grouped_ids)
    end
  end

  def validate_simple_qualifications(precondition_ids)
    precondition_ids.each do |id|
      errors << id unless reactivateable?(id)
    end
  end

  def validate_grouped_qualifications(grouped_ids)
    unless any_grouped_qualifications?(grouped_ids)
      errors << :some_qualifications
    end
  end

  def any_grouped_qualifications?(grouped_ids)
    grouped_ids.any? do |ids|
      ids.all? { |id| reactivateable?(id) }
    end
  end

  def person_qualifications
    @person_qualifications ||=
      person.qualifications.where(qualification_kind_id: course_preconditions.map(&:id))
  end

  def course_preconditions
    course.kind.qualification_kinds('precondition', 'participant')
  end

  def reactivateable?(qualification_kind_id)
    person_qualifications.
      select { |q| q.qualification_kind_id == qualification_kind_id }.
      any? { |qualification| qualification.reactivateable?(course.start_date) }
  end

  def old_enough?
    (course.start_date.end_of_year - course_minimum_age.years) >= person.birthday.to_date
  end

  def birthday_error_text
    translate(:below_minimum_age, course_minimum_age: course_minimum_age)
  end

  def some_qualifications_error_text
    translate(:some_qualifications_missing)
  end

  def qualifications_error_text
    kinds = QualificationKind.includes(:translations).find(errors)
    translate(:qualifications_missing, missing: kinds.collect(&:label).join(', '))
  end

end
