# frozen_string_literal: true

#  Copyright (c) 2020-2023, Die Mitte Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# == Schema Information
#
# Table name: person_duplicates
#
#  id          :bigint           not null, primary key
#  ignore      :boolean          default(FALSE), not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  person_1_id :integer          not null
#  person_2_id :integer          not null
#
# Indexes
#
#  index_person_duplicates_on_person_1_id_and_person_2_id  (person_1_id,person_2_id) UNIQUE
#

Fabricator(:person_duplicate) do
  person_1 { Fabricate(:person) }
  before_create do |d, _t|
    p2 = person_1.class.new
    People::DuplicateLocator::DUPLICATION_ATTRS.each do |attr|
      p2[attr] = person_1[attr]
    end
    p2.email = person_1.email.sub("hitobito.example.com", "duplicates.example.com")
    p2.save!
    d.person_2 = p2
  end
end
