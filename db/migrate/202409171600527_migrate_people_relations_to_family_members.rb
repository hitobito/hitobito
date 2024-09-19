# frozen_string_literal: true

#  Copyright (c) 2024, Pfadibewegung Schweiz. This file is part of
#  hitobito_pbs and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pbs.

class MigratePeopleRelationsToFamilyMembers < ActiveRecord::Migration[6.1]
  def up
    return unless defined?(PeopleRelation) && PeopleRelation.any?

    @existing_people_relation_count = PeopleRelation.count
    @existing_family_member_count = FamilyMember.count

    say_with_time('migrating PeopleRelation to FamilyMember') do
      PeopleRelation.transaction do
        unwind_all_people_relations
      end
      report
    end
  end

  # Prevent FamilyKeyMismatch by following the siblings in order.
  # Still, this algorithm can lead to overly large families,
  # as each new sibling is added to the existing family, even
  # when it's only supposed to be a half-sibling (which are not supported
  # by `FamilyMember``).
  def unwind_all_people_relations
    stack = []

    while (person_id = stack.shift || PeopleRelation.first&.head_id).present?
      stack += unwind_people_relations_of_person(person_id).compact.map(&:other_id)
    end
  end

  def unwind_people_relations_of_person(person_id)
    # one direction should also cover the opposite
    PeopleRelation.where(head_id: person_id).map do |people_relation|
      family_member = build_family_member_from_person_relation(people_relation)

      if family_member.new_record?
        family_member.save! && people_relation.destroy!
        next family_member
      else
        people_relation.destroy!
        next nil
      end
    rescue FamilyKeyMismatch => e
      nil
    end
  end

  def build_family_member_from_person_relation(people_relation)
    FamilyMember.find_or_initialize_by(person_id: people_relation.head_id,
                                       other_id: people_relation.tail_id).tap do |family_member|
      family_member.kind = people_relation.kind
    end
  end

  def report
    info = [
      "Before: #{@existing_people_relation_count} PeopleRelation/#{@existing_family_member_count} FamilyMember",
      "After: #{PeopleRelation.count} PeopleRelation/#{FamilyMember.count} FamilyMember"
    ]

    suspicously_large_families = FamilyMember.group(:family_key).count.filter { _2 > 110 }.keys
    suspicously_large_families.each do |family_key|
      members = FamilyMember.where(family_key: family_key).flat_map { [_1.person_id, _1.other_id] }.uniq
      info << "Family #{family_key} has #{members.count} members: #{members.map { Person.find(_1)&.to_s }.join(', ')}"
    end

    info.each { Rails.logger.info(_1) }
  end
end
