# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Event::Qualifier
  class Leader < Base

    def issue_qualifications
      Qualification.transaction do
        prolong_existing(qualification_kinds)
      end
    end

    def revoke_qualifications
      Qualification.transaction do
        remove(qualification_kinds)
      end
    end

    def nothing_changed?
      qualification_kinds.present? && prolonged.blank?
    end
  end
end
