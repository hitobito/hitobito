# frozen_string_literal: true

#  Copyright (c) 2024, Pfadibewegung Schweiz. This file is part of
#  hitobito_pbs and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pbs.

class MigratePeopleRelationsToFamilyMembers < ActiveRecord::Migration[6.1]
  def up
    return unless defined?(PeopleRelation)

    PeopleRelation.transaction do
      unwind_people_relations
    end
  end

  # prevent FamilyKeyMismatch by following the
  def unwind_people_relations
    stack = []

    while (person_id = stack.shift || PeopleRelation.first&.head_id).present?
      stack += unwind_person_relations(person_id).map(&:other_id)
    end
  end

  def unwind_person_relations(person_id)
    # one direction should also cover the opposite
    PeopleRelation.where(head_id: person_id).map do |person_relation|
      family_member = FamilyMember.create!(person_id: person_relation.head_id,
                                           other_id: person_relation.tail_id,
                                           kind: person_relation.kind)
      person_relation.destroy!
      family_member
    end
  end
end
