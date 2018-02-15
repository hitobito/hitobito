#  Copyright (c) 2012-2018, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Person::HouseholdsController < ApplicationController

  def new
    authorize!(:update, person)
    person.attributes = permitted_params
    @invalid = !household.assign
  end

  private

  def household
    @household ||= Person::Household.new(person, current_ability, other_person)
  end

  def other_person
    @other_person ||= Person.find_by(id: params[:other_person_id])
  end

  def person
    @person ||= Person.find(params[:person_id])
  end

  def permitted_params
    params.require(:person).permit(:address,
                                   :zip_code,
                                   :town,
                                   :country,
                                   household_people_ids: [])
  end

end
