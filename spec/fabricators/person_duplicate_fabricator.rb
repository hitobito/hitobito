# frozen_string_literal: true

#  Copyright (c) 2020-2023, Die Mitte Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

Fabricator(:person_duplicate) do
  person_1 { Fabricate(:person) }
  before_create do |d, _t|
    p2 = person_1.class.new
    People::DuplicateLocator::DUPLICATION_ATTRS.each do |attr|
      p2[attr] = person_1[attr]
    end
    p2.email = person_1.email.sub('hitobito.example.com', 'duplicates.example.com')
    p2.save!
    d.person_2 = p2
  end
end
