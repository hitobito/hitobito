class JsonApi::PeopleController < ActionController::API

  def index
    people = PersonResource.all
    render(jsonapi: people)
  end
end
