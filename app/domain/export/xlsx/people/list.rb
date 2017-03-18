# encoding: utf-8

#  Copyright (c) 2012-2014, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Export::Xlsx::People
  class List < Export::Xlsx::Base
    include Translatable
    include Export::Agnostic::People::List

    MAX_DATES = 3

    self.row_class = Export::Xlsx::People::Row
    self.style_class = Export::Xlsx::People::Style


    private
    def model_class
      @model_class ||= list.first ? list.first.class : ::Person
    end

  end
end
