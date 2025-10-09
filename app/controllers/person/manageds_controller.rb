# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_youth.

class Person::ManagedsController < PeopleManagersController
  helper_method :create_managed?

  self.assoc = :people_manageds

  private

  def create_managed?
    cannot?(:lookup_manageds, Person) &&
      FeatureGate.enabled?("people.people_managers.self_service_managed_creation")
  end

  def redirect_to_path
    person_manageds_path(person)
  end

  def model_params
    params.require(:people_manager).permit(
      :managed_id,
      managed_attributes: [:first_name, :last_name, :gender, :birthday]
    )
  end
end
