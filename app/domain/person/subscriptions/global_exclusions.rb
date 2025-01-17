# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Person::Subscriptions::GlobalExclusions
  attr_reader :person_id

  def initialize(person_id)
    @person_id = person_id
  end

  def excluding_mailing_list_ids
    return [] if lists_with_filter.none?

    lists_with_filter.where.not(id: including_lists.pluck(:id)).select(:id)
  end

  private

  def including_lists
    MailingList
      .unscope(:select)
      .select("mailing_lists.id")
      .joins("LEFT JOIN people ON people.id = #{person_id}")
      .merge(build_filter_chain)
      .where(people: {id: person_id})
  end

  def build_filter_chain
    first, *rest = MailingList.with_filter_chain

    rest.inject(apply_filter(first)) { |scope, list| scope.or(apply_filter(list)) }
  end

  def apply_filter(list) = list.filter_chain.filter(people_scope).where(mailing_lists: {id: list.id})

  def lists_with_filter = MailingList.with_filter_chain

  def people_scope = Person.where(id: person_id)
end
