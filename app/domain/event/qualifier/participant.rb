module Event::Qualifier
  class Participant < Base

    # Does the person have all qualifications from the event?
    # required for view to display checksign
    def qualified?
      obtained_qualifications.present? &&
      has_all_qualifications? && 
      has_all_prolongations?(prolongation_kind_ids)
    end
  
    def issue
      Qualification.transaction do
        create_qualifications
        create_prolongations(prolongation_kind_ids)
      end
    end
  
    def revoke
      Qualification.transaction do
        remove_qualifications(qualification_kind_ids + prolongation_kind_ids)
      end
    end
    
  end
end