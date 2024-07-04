#  Copyright (c) 2012-2021, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Person::HouseholdsController < ApplicationController
  def new
    authorize!(:update, person)
    person.attributes = permitted_params
    household.assign
    if @invalid = !household.valid?
      # we must remove again the other_person and its potential housemates from the list,
      # otherwise the user won't be able to save the form as there is no ui to remove them
      person.household_people_ids -= other_person_and_household_people_ids
    end
  end

  protected

  def permitted_address_fields
    [:address, :zip_code, :town, :country]
  end

  private

  def household
    @household ||= Person::Household.new(person, current_ability, other_person)
  end

  def other_person_and_household_people_ids
    [other_person.id, *other_person.household_people.map(&:id)]
  end

  def other_person
    @other_person ||= Person.find_by(id: params[:other_person_id])
  end

  def person
    @person ||= Person.find(params[:person_id])
  end

  def permitted_params
    params.require(:person).permit(permitted_address_fields,
      household_people_ids: [])
  end
end
