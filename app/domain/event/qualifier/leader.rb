module Event::Qualifier
  class Leader < Base

    # Does the person have all qualifications from the event?
    # required for view to display checksign
    def qualified?
      obtained_qualifications.present? && has_all_prolongations?(qualification_kind_ids)
    end
      
    def issue
      Qualification.transaction do
        create_prolongations(qualification_kind_ids)
      end
    end
  
    def revoke
      Qualification.transaction do
        remove_qualifications(qualification_kind_ids)
      end
    end
  end
end