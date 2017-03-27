# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Export::Csv::People

  # Attributes of people we want to include
  class PeopleAddress < Export::Csv::Base

    include Export::Agnostic::People::List

    self.model_class = ::Person
    self.row_class = PersonRow


  end
end
