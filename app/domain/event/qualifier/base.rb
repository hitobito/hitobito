module Event::Qualifier
  
  class Base < Struct.new(:participation)

    def qualifications
      obtained_qualifications_for(qualification_kind_ids)
    end

    private
  
    def has_all_qualifications?
      qualification_kind_ids.size == obtained_qualifications_for(qualification_kind_ids).size
    end
  
    def has_all_prolongations?(kind_ids)
      obtained_qualifications_for(kind_ids).size == 
      existing_qualifications(kind_ids).pluck(:qualification_kind_id).uniq.size
    end
  
    def create_qualifications
      event.kind.qualification_kinds.each do |k|
        create_qualification(k)
      end
    end
  
    # creates new qualification for existing qualifications (prologation mechanism)
    def create_prolongations(kind_ids)
      if kind_ids.present?
        existing_qualifications(kind_ids).includes(:qualification_kind).each do |q|
          create_qualification(q.qualification_kind)
        end
      end
    end
  
    # The qualifications a participant had before this event
    def existing_qualifications(kind_ids)
      person.qualifications.
             active(event.start_date).
             where(qualification_kind_id: kind_ids)
    end
  
    def create_qualification(kind)
      person.qualifications.create(qualification_kind: kind,
                                   origin: event.to_s,
                                   start_at: qualification_date)
    end
  
    def remove_qualifications(kind_ids)
      obtained_qualifications_for(kind_ids).each { |q| q.destroy }
    end
  
    def qualification_kind_ids
      @qualification_kind_ids ||= event.kind_id? ? event.kind.qualification_kind_ids.to_a : []
    end
  
    def prolongation_kind_ids
      @prolongation_kind_ids ||= event.kind.prolongation_ids.to_a
    end
  
    def obtained_qualifications_for(kind_ids)
      obtained_qualifications.select {|q| kind_ids.include?(q.qualification_kind_id) }
    end
  
    def obtained_qualifications
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
end