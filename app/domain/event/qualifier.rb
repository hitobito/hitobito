class Event::Qualifier < Struct.new(:participation)
    
   # Does the person have all qualifications from the event?
  def qualified?
    qualification_kind_ids.size == qualifications.size
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
    qualifications_scope(qualification_kind_ids)
  end
  
  private
  
  def create_qualifications
    event.kind.qualification_kinds.each do |q|
      create_qualification(q)
    end
  end
  
  def create_prolongations
    if prolongations.present?
      person.qualifications.active.
                            where(qualification_kind_id: prolongations.collect(&:id)).
                            includes(:qualification_kind).
                            each do |q|
        create_qualification(q.qualification_kind)
      end
    end
  end
  
  def create_qualification(kind)
    person.qualifications.create(qualification_kind: kind, 
                                 start_at: event.qualification_date)
  end
  
  def remove_qualifications
    qualifications.destroy_all
  end
  
  def remove_prolongations
    qualifications_scope(prolongations.collect(&:id)).destroy_all
  end
    
  
  def qualification_kind_ids
    @qualification_kind_ids ||= event.kind_id? ? event.kind.qualification_kind_ids.to_a : []
  end
  
  def prolongations
    @prolongations ||= event.kind.prolongations.to_a
  end
  
  def qualifications_scope(kind_ids)
    if kind_ids.present?
      person.qualifications.where(qualification_kind_id: kind_ids, 
                                  start_at: event.qualification_date)
    else
      Qualification.where('1=0') # none!
    end
  end
  
  def person
    participation.person
  end
  
  def event
    participation.event
  end
  
end