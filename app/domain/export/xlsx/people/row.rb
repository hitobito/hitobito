# encoding: utf-8

#  Copyright (c) 2012-2014, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Export::Xlsx::People
  class Row < Export::Xlsx::Row
    include Export::Agnostic::People::Row


    self.dynamic_attributes = { /^phone_number_/ => :phone_number_attribute,
                                /^social_account_/ => :social_account_attribute,
                                /^additional_email_/ => :additional_email_attribute,
                                /^people_relation_/ => :people_relation_attribute,
                                /^qualification_kind_/ => :qualification_kind}


    def birthday
      entry.birthday.try(:to_s)
    end

  end
end
