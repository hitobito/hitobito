# frozen_string_literal: true

#  Copyright (c) 2022, Schweizer Wanderwege. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class JsonApi::PeopleController < JsonApiController

  def index
    authorize!(:index_people, Group)
    people = PersonResource.all(params, index_people_scope)
    render(jsonapi: people)
  end

  def show
    authorize!(:show, entry)
    person = PersonResource.find(params)
    render(jsonapi: person)
  end

  def update
    authorize!(:update, entry)
    resource = PersonResource.find(params)
    Person.transaction do
      if resource.update_attributes
        render(jsonapi: resource)
      else
        render(jsonapi_errors: resource)
      end
    end
  end

  private

  def index_people_scope
    Person.accessible_by(PersonReadables.new(current_user ||
                                             service_token_user ||
                                             current_oauth_token.person))
  end

  def entry
    Person.find(params[:id])
  end

end
