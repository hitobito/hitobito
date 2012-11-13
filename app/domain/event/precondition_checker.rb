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
    errors << :birthday unless starts_before_years(person.birthday, course_minimum_age)
  end

  def starts_before_years(date, amount)
    date && (date + amount.years) >= course_start_at
  end

  def validate_precondition(qualification_kind)
    validity = qualification_kind.validity
    person_qualification = person_qualification_for(qualification_kind)
    errors << qualification_kind.label unless qualification_valid?(person_qualification,validity)
  end

  def person_qualifications
    @person_qualifications ||= person.qualifications
  end

  def person_qualification_for(qualification_kind)
    person_qualifications.first { |qualification| qualification.kind == qualification_kind }
  end

  def qualification_valid?(qualification,validity)
    qualification && starts_before_years(qualification.start_at.to_time_in_current_zone, validity)
  end

  def person_age
    dob = person.birthday
    if dob
      now = Time.now.utc.to_date
      now.year - dob.year - ((now.month > dob.month || (now.month == dob.month && now.day >= dob.day)) ? 0 : 1)
    else
      0
    end
  end

  def birthday_error_text
    "Altersgrenze von #{course_minimum_age} unterschritten, du bist #{person_age} Jahre alt." 
  end

  def qualifications_error_text
    "Folgende Qualifikationen fehlen: #{errors.join(", ")}"
  end

end

