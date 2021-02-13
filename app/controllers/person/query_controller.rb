#  Copyright (c) 2012-2015, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Person::QueryController < ApplicationController
  class_attribute :serializer
  self.serializer = :as_typeahead

  before_action :authorize_action

  delegate :model_class, to: :class

  # GET ajax, for auto complete fields, without @group
  def index
    people = []
    if params.key?(:q) && params[:q].size >= 3
      people = list_entries.limit(10)
      people = decorate(people)
    end

    render json: people.collect { |p| p.public_send(serializer) }
  end

  private

  def list_entries
    scope.order_by_name
  end

  def scope
    Person.only_public_data
  end

  def authorize_action
    authorize!(:query, Person)
  end

  include Searchable

  self.search_columns = [:first_name, :last_name, :company_name, :nickname, :town]

  class << self
    def model_class
      Person
    end
  end
end
