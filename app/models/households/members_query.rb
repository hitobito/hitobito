# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Households::MembersQuery
  SAME_ADDRESS_IGNORED_ATTRS = [:country, :address_care_off].freeze

  def initialize(current_user, person_id, writables_scope = nil)
    @current_user = current_user
    @person = current_user if person_id.blank? || current_user.id == person_id
    @person ||= Person.find(person_id)
    @writables_scope = writables_scope || Person.only_public_data
  end

  def scope
    scope = writable_people.distinct.joins(roles: :group)
    scope = scope.or(same_address_query) if @person.address_attrs.present?
    scope = scope.or(herself_query) if @current_user.present?
    scope
  end

  private

  def writable_people
    Person.accessible_by(PersonWritables.new(@current_user, @writables_scope))
  end

  def same_address_query
    @writables_scope.distinct.joins(roles: :group)
                    .where(@person.address_attrs.except(*SAME_ADDRESS_IGNORED_ATTRS))
                    .where.not(id: @person.id)
  end

  def herself_query
    Person.distinct.where(id: @current_user.id)
  end
end
