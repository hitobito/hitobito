class Event::Qualifier < Struct.new(:participation)

  # Does the person have all qualifications from the event?
  # required for view to display checksign
  def qualified?
    if leader?
      has_all_qualifications?
    else
      has_all_qualifications? && has_all_prolongations?
    end
  end

  def issue
    Qualification.transaction do
      if leader?
        create_prolongations(qualification_kind_ids)
      else
        create_qualifications
        create_prolongations(prolongation_kind_ids)
      end
    end
  end

  def revoke
    Qualification.transaction do
      if leader?
        remove_prolongations(qualification_kind_ids)
      else
        remove_qualifications
        remove_prolongations(prolongation_kind_ids)
      end
    end
  end

  # The qualifications a participant got in this event
  def qualifications
    qualifications_for(qualification_kind_ids)
  end

  # The qualifications of a participant that got prolonged with this event
  def prolongations(qualification_kind_ids)
    qualifications_for(qualification_kind_ids)
  end

  private

  def leader?
    participation.roles.where(type: event.class.leader_types.map(&:sti_name)).exists?
  end

  def has_all_qualifications?
    qualification_kind_ids.size == qualifications.size
  end

  def has_all_prolongations?
    prolongations(prolongation_kind_ids).size == existing_qualifications(prolongation_kind_ids).pluck(:qualification_kind_id).uniq.size
  end

  def create_qualifications
    event.kind.qualification_kinds.each do |q|
      create_qualification(q)
    end
  end

  # creates new qualification for existing qualifications (prologation mechanism)
  def create_prolongations(qualification_kind_ids)
    if qualification_kind_ids.present?
      existing_qualifications(qualification_kind_ids).includes(:qualification_kind).each do |q|
        create_qualification(q.qualification_kind)
      end
    end
  end

  # The qualifications a participant had before this event
  def existing_qualifications(qualification_kind_ids)
    person.qualifications.active(event.start_date).
      where(qualification_kind_id: qualification_kind_ids)
  end

  def create_qualification(kind)
    person.qualifications.create(qualification_kind: kind,
                                 origin: event.to_s,
                                 start_at: qualification_date)
  end

  def remove_qualifications
    qualifications.each { |q| q.destroy }
  end

  def remove_prolongations(qualification_kind_ids)
    prolongations(qualification_kind_ids).each { |q| q.destroy }
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
