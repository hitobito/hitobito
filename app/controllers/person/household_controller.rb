# encoding: utf-8

#  Copyright (c) 2020, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Person::HouseholdController < ApplicationController

  before_action :authorize_action

  delegate :model_class, to: :class

  # GET ajax, for auto complete field when editing household of person
  def index
    render json: decorate(list_entries.limit(10)).collect(&:as_typeahead_with_address)
  end

  private

  def list_entries
    Person.where(accessible_people_condition)
          .or(Person.where(same_address_condition))
          .only_public_data
          .order_by_name
  end

  def accessible_people_condition
    {
      id: Person.accessible_by(PersonReadables.new(current_user)).pluck(:id)
    }
  end

  def same_address_condition
    {
      address: current_user.address,
      zip_code: current_user.zip_code,
      town: current_user.town
    }
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
