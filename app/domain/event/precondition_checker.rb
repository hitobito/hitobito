# encoding: UTF-8
class Event::PreconditionChecker < Struct.new(:course, :person)
  extend Forwardable
  def_delegator 'course.dates.first', :start_at, :course_start_at
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
      validate_precondition(qualification_kind)
    end
  end

  def errors_text
    text = []
    text << "<b>Vorbedingungen für Anmeldung sind nicht erfüllt.</b>"
    text << birthday_error_text if errors.delete(:birthday)
    text << qualifications_error_text  if errors.present?
    text
  end

  private
  def validate_minimum_age
    errors << :birthday if person_age_at_course_start < course_minimum_age
  end
  def validate_precondition(qualification_kind)
    errors << qualification_kind.label unless person_qualified_for(qualification_kind)
  end

  def person_qualifications
    @person_qualifications ||= person.qualifications
  end

  def person_qualified_for(qualification_kind)
    person_qualifications.active.find do |qualification| 
      qualification.qualification_kind == qualification_kind  && 
        qualification.cover?(course_start_at.to_date)
    end
  end

  def person_age_at_course_start
    age = 0
    if birthday = person.birthday
      age = course_start_at.year - birthday.year
      age -= ((course_start_at.month > birthday.month || 
               (course_start_at.month == birthday.month && course_start_at.day > birthday.day)) ? 1 : 0)
    end
    age
  end

  def birthday_error_text
    "Altersgrenze von #{course_minimum_age} unterschritten, du bist #{person_age_at_course_start} Jahre alt." 
  end

  def qualifications_error_text
    "Folgende Qualifikationen fehlen: #{errors.join(", ")}"
  end

end

