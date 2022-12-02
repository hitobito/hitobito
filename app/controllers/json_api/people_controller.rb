class JsonApi::PeopleController < JsonApiController

  def index
    authorize!(:index_people, Group)
    people = PersonResource.all(api_params, index_people_scope)
    render(jsonapi: people)
  end

  private

  def index_people_scope
    Person.accessible_by(PersonReadables.new(current_user || service_token_user || current_oauth_token.person))
  end

end
