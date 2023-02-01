# frozen_string_literal: true

#  Copyright (c) 2012-2021, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Person::QueryController < ApplicationController

  class_attribute :serializer
  self.serializer = :as_typeahead # method to call on person when serializing

  before_action :authorize_action

  delegate :model_class, to: :class

  # GET ajax, for auto complete fields, without @group
  def index
    people = []
    if search_param.size >= 3
      people = if include_groups?
        list_entries.joins(:groups).limit(10)
      else
        list_entries.limit(10)
      end
      people = decorate(people)
    end
        
    render json: serialize_people(people)
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
  
  # serialize people and include matched group if present
  def serialize_people(people)
    if include_groups?
      people.collect do |p|
        group = p.groups.find do |g|
          search_param_split.any? { |s| g.name.downcase.include? s.downcase }
        end

        p.public_send(serializer, group: group)
      end
    else
      people.collect { |p| p.public_send(serializer) }
    end
  end

  include Searchable

  # dynamically update search_columns based on current request
  def search_columns
    columns = [:first_name, :last_name, :company_name, :nickname, :town]
    if include_groups?
      columns << :'groups.name'
    end
    
    columns
  end

  def include_groups?
    # prevent people from just searching for a group, two terms required
    search_param_split.size >= 2
  end
    
  def search_param_split
    @search_param_split ||= search_param.split(/\s+/)
  end

  class << self

    def model_class
      Person
    end

  end

end
