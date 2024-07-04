# frozen_string_literal: true

#  Copyright (c) 2020, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Person::QueryHouseholdController < Person::QueryController
  self.serializer = :as_typeahead_with_address

  private

  def scope
    Households::MembersQuery.new(current_user, params[:person_id]).scope
  end
end
