# frozen_string_literal: true

#  Copyright (c) 2012-2021, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Person::QueryController < ApplicationController

  class_attribute :serializer, default: :as_typeahead
  class_attribute :limit, default: 10

  before_action :authorize_action

  delegate :model_class, to: :class

  # GET ajax, for auto complete fields, without @group
  def index
    people = []
    if search_param.size >= 3
      people = list_entries.limit(limit)
      people = decorate(people)
    end
    if limit_by_permission
      people.select! { |p| can?(limit_by_permission.to_sym, p) }
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

  def limit_by_permission
    params[:limit_by_permission]
  end

  include Searchable

  self.search_columns = [:first_name, :last_name, :company_name, :nickname, :town]

  class << self

    def model_class
      Person
    end

  end

end
