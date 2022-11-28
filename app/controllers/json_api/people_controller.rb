class JsonApi::PeopleController < ApplicationController

  def index
    authorize!(:index_people, Group.first) # TODO adjust to actual authorize call, this is more of a test
    people = PersonResource.all
    render(jsonapi: people)
  end
end
