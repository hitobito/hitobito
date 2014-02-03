# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Event::PreconditionChecker < Struct.new(:course, :person)
  extend Forwardable
  def_delegator 'course.kind', :minimum_age, :course_minimum_age
  def_delegator 'course.kind', :preconditions, :course_preconditions
  def_delegator 'errors', :empty?, :valid?
  attr_reader :errors

  def initialize(*args)
    super
    @errors = []
    validate
  end

  def validate
    validate_minimum_age if course_minimum_age

    course_preconditions.each do |qualification_kind|
      if !reactivateable?(qualification_kind)
        errors << qualification_kind.label
      end
    end
  end

  def errors_text
    text = []
    if errors.present?
      text << '<b>Vorbedingungen für Anmeldung sind nicht erfüllt.</b>'
      text << birthday_error_text if errors.delete(:birthday)
      text << qualifications_error_text  if errors.present?
    end
    text
  end

  private

  def validate_minimum_age
    errors << :birthday unless person.birthday && old_enough?
  end

  def person_qualifications
    @person_qualifications ||= person.qualifications.where(qualification_kind_id: course_preconditions.map(&:id))
  end

  def reactivateable?(qualification_kind)
    person_qualifications.
      select {|q| q.qualification_kind_id == qualification_kind.id }.
      any? { |qualification| qualification.reactivateable?(course.start_date) }
  end

  def old_enough?
    (course.start_date.end_of_year - course_minimum_age.years) >= person.birthday.to_date
  end

  def birthday_error_text
    "Altersgrenze von #{course_minimum_age} unterschritten."
  end

  def qualifications_error_text
    "Folgende Qualifikationen fehlen: #{errors.join(", ")}"
  end

end
