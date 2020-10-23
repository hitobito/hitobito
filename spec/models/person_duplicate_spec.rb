# frozen_string_literal: true

#  Copyright (c) 2012-2020, CVP Schweiz. This file is part of
#  hitobito_cvp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_cvp.

# == Schema Information
#
# Table name: person_doublets
#
#  id                   :integer          not null, primary key
#  person_1_id          :integer          not null
#  person_2_id          :integer          not null
#  acknowledged         :boolean          default(FALSE), not null
#

require 'spec_helper'

describe PersonDuplicate do

  context 'before_save' do
    context 'assign_persons_sorted_by_id' do
      it 'assigns person with lower id to person_1' do
        people = [people(:top_leader), people(:bottom_member)]
        lower_id_person, higher_id_person = people.sort_by(&:id)

        duplicate = PersonDuplicate.create!(person_1: higher_id_person, person_2: lower_id_person)

        expect(duplicate.person_1).to eq(lower_id_person)
        expect(duplicate.person_2).to eq(higher_id_person)

        duplicate.update!(person_1: higher_id_person, person_2: lower_id_person)

        expect(duplicate.person_1).to eq(lower_id_person)
        expect(duplicate.person_2).to eq(higher_id_person)
      end
    end
  end
end
