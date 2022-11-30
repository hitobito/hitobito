class JsonApi::PeopleController < JsonApiController

  # people_layer_or_below_ability = true

  def index
    authorize!(:index_people, Group)
    people = PersonResource.all({}, index_people_scope)
    render(jsonapi: people)
  end

  private

  def index_people_scope
    Person.accessible_by(PersonReadables.new(current_user || service_token_user))
  end

end
