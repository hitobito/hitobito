# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_youth.

class Person::ManagersController < PeopleManagersController
  self.assoc = :people_managers

  private

  def redirect_to_path
    person_managers_path(person)
  end

  def model_params
    params.require(:people_manager).permit(:manager_id)
  end
end
