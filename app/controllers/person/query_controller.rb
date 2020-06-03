# encoding: utf-8

#  Copyright (c) 2012-2015, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Person::QueryController < ApplicationController

  before_action :authorize_action

  delegate :model_class, to: :class

  # GET ajax, for auto complete fields, without @group
  def index
    people = []
    if params.key?(:q) && params[:q].size >= 3
      people = list_entries.limit(10)
      people = decorate(people)
    end

    if params.key?(:with_address)
      render json: people.collect(&:as_typeahead_with_address)
    else
      render json: people.collect(&:as_typeahead)
    end
  end

  private

  def list_entries
    Person.only_public_data.order_by_name
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
