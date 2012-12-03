class Event::Qualifier < Struct.new(:participation)
    
  # Does the person have all qualifications from the event?
  def qualified?
    has_all_qualifications? && has_all_prolongations?
  end
  
  def issue
    Qualification.transaction do
      create_qualifications
      create_prolongations
    end
  end
  
  def revoke
    Qualification.transaction do
      remove_qualifications
      remove_prolongations
    end
  end
  
  # The qualifications a participant got in this event
  def qualifications
    qualifications_for(qualification_kind_ids)
  end
  
  def prolongations
    qualifications_for(prolongation_kind_ids)
  end
  
  private
  
  def has_all_qualifications?
    qualification_kind_ids.size == qualifications.size
  end
  
  def has_all_prolongations?
    prolongations.size == prolonged_qualifications.pluck(:qualification_kind_id).uniq.size
  end
  
  def create_qualifications
    event.kind.qualification_kinds.each do |q|
      create_qualification(q)
    end
  end
  
  def create_prolongations
    if prolongation_kind_ids.present?
      prolonged_qualifications.includes(:qualification_kind).each do |q|
        create_qualification(q.qualification_kind)
      end
    end
  end
  
  def prolonged_qualifications
    person.qualifications.active.
                          where(qualification_kind_id: prolongation_kind_ids)
  end
  
  def create_qualification(kind)
    person.qualifications.create(qualification_kind: kind, 
                                 origin: event.to_s, 
                                 start_at: qualification_date)
  end
  
  def remove_qualifications
    qualifications.each { |q| q.destroy }
  end
  
  def remove_prolongations
    prolongations.each { |q| q.destroy }
  end
  
  def qualification_kind_ids
    @qualification_kind_ids ||= event.kind_id? ? event.kind.qualification_kind_ids.to_a : []
  end
  
  def prolongation_kind_ids
    @prolongation_kind_ids ||= event.kind.prolongation_ids.to_a
  end
  
  def qualifications_for(kind_ids)
    event_qualifications.select {|q| kind_ids.include?(q.qualification_kind_id) }
  end
  
  def event_qualifications
    @event_qualifications ||= person.qualifications.where(start_at: qualification_date).to_a
  end
  
  def qualification_date
    event.qualification_date
  end
  
  def person
    participation.person
  end
  
  def event
    participation.event
  end
  
end
