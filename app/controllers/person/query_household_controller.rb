# encoding: utf-8

#  Copyright (c) 2020, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Person::QueryHouseholdController < Person::QueryController

  self.serializer = :as_typeahead_with_address

  private

  def scope
    scope = Person.accessible_by(PersonWritables.new(current_user)).distinct.joins(roles: :group)
    scope = scope.or(same_address_query) if address_attrs.present?
    scope
  end

  def same_address_query
    Person.distinct.only_public_data.joins(roles: :group)
      .where(address_attrs)
      .where.not(id: params[:person_id])
  end

  def address_attrs
    person = Person.find(params[:person_id])
    {
      address: person.address,
      zip_code: person.zip_code,
      town: person.town
    }.compact
  end

end
