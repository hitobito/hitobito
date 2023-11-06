# frozen_string_literal: true

#  Copyright (c) 2023, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class People::Destroyer

  def initialize(person)
    @person = person
  end

  def run
    destroy_leftover_family_member_entries!
    resolve_leftover_household!
    nullify_invoices!

    @person.destroy!
  end

  private

  def destroy_leftover_family_member_entries!
    leftover_family_members.destroy_all
  end

  def resolve_leftover_household!
    leftover_household_person&.update!(household_key: nil)
  end

  def nullify_invoices!
    Invoice.where(recipient: @person).update(recipient_email: @person.email,
                                             recipient_address: invoice_address,
                                             recipient: nil)
    Invoice.where(creator: @person).update(creator: nil)
  end

  def leftover_family_members
    FamilyMember.where(family_key: @person.family_members.pluck(:family_key))
                .having('COUNT(*) <= 2')
                .group(:family_key)
  end

  def leftover_household_person
    @person.household_people.first if @person.household_people.size == 1
  end

  def invoice_address
    Person::Address.new(@person).for_invoice
  end

end
