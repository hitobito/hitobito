# frozen_string_literal: true

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
