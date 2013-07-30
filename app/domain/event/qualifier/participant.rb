# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

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