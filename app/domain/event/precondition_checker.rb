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
    grouped_ids_and_validity = course.kind
                                     .grouped_qualification_kind_ids_and_validity('precondition',
                                                                                  'participant')
    if grouped_ids_and_validity.size == 1
      validate_simple_qualifications(grouped_ids_and_validity.first)
    elsif grouped_ids_and_validity.size > 1
      validate_grouped_qualifications(grouped_ids_and_validity)
    end
  end

  def validate_simple_qualifications(precondition_ids_and_validity)
    precondition_ids_and_validity.each do |id, validity|
      errors << id unless valid_qualification?(id, validity)
    end
  end

  def validate_grouped_qualifications(grouped_ids_and_validity)
    unless any_grouped_qualifications?(grouped_ids_and_validity)
      errors << :some_qualifications
    end
  end

  def any_grouped_qualifications?(grouped_ids_and_validity)
    grouped_ids_and_validity.any? do |ids|
      ids.all? { |id, validity| valid_qualification?(id, validity) }
    end
  end

  def person_qualifications
    @person_qualifications ||=
      person.qualifications.where(qualification_kind_id: course_preconditions.map(&:id))
  end

  def course_preconditions
    course.kind.qualification_kinds('precondition', 'participant')
  end

  def valid_qualification?(qualification_kind_id, validity)
    scope = case validity.to_sym
    when :valid
      person_qualifications.active(course.start_date)
    when :valid_or_reactivatable
      person_qualifications.reactivateable(course.start_date)
    when :valid_or_expired
      person_qualifications
    end
    scope.any? { |q| q.qualification_kind_id == qualification_kind_id }
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
