# frozen_string_literal: true

#  Copyright (c) 2021, Katholische Landjugendbewegung Paderborn. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# == Schema Information
#
# Table name: family_members
#
#  id         :bigint           not null, primary key
#  family_key :string           not null
#  kind       :string           not null
#  other_id   :bigint           not null
#  person_id  :bigint           not null
#
# Indexes
#
#  index_family_members_on_family_key              (family_key)
#  index_family_members_on_other_id                (other_id)
#  index_family_members_on_person_id               (person_id)
#  index_family_members_on_person_id_and_other_id  (person_id,other_id) UNIQUE
#

Fabricator(:family_member) do
  person { Fabricate(:person) }
  kind { "sibling" }
  other { Fabricate(:person) }
end
