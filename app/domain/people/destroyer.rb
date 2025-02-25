# frozen_string_literal: true

#  Copyright (c) 2023, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class People::Destroyer
  def initialize(person)
    @person = person
    @household = person.household
  end

  def run
    Person.transaction do
      destroy_leftover_family_member_entries!
      remove_from_household! unless @household.empty?
      nullify_invoices!

      @person.destroy!
    end
  end

  private

  def remove_from_household!
    if @household.valid? && @household.people.all?(&:valid?)
      @household.remove(@person)
      @household.save!
    elsif @household.people.size == 2
      Person.where(id: @household.people.map(&:id))
        .update_all(household_key: nil)
    end
  end

  def destroy_leftover_family_member_entries!
    FamilyMember.where(id: leftover_family_members).destroy_all
  end

  def nullify_invoices!
    Invoice.where(recipient: @person).update(recipient_email: @person.email,
      recipient_address: invoice_address,
      recipient: nil)
    Invoice.where(creator: @person).update(creator: nil)
  end

  def leftover_family_members
    FamilyMember.select("MAX(family_members.id)")
      .where(family_key: @person.family_members.pluck(:family_key))
      .having("COUNT(*) <= 2")
      .group(:family_key)
  end

  def invoice_address
    Person::Address.new(@person).for_invoice
  end
end
