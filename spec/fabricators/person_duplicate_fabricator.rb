# frozen_string_literal: true

#  Copyright (c) 2020, CVP Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

Fabricator(:person_duplicate) do
  person_1 { Fabricate(:person) }
  before_save do |d,t|
    p2 = d.person_1.dup
    p2.email = p2.email.sub('hitobito.example.com', 'duplicates.example.com')
    p2.save!
    d.person_2 = p2
  end
end
