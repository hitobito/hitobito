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

class PersonDuplicate < ActiveRecord::Base

  belongs_to :person_1, class_name: 'Person'
  belongs_to :person_2, class_name: 'Person'

  before_save :assign_persons_sorted_by_id

  # Sorting by id to only allow a single PersonDuplicate entry per Person combination
  def assign_persons_sorted_by_id
    people = [self.person_1, self.person_2].sort_by(&:id)

    self.person_1 = people.first
    self.person_2 = people.last
  end
end
