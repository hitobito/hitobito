# encoding: utf-8

#  Copyright (c) 2017, Dachverband Schweizer Jugendparlamente. This file is
#  part of hitobito and licensed under the Affero General Public License
#  version 3 or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Person::CompanyNameController < ApplicationController

  before_action :authorize_action

  delegate :model_class, to: :class

  # GET ajax, for auto complete fields, only the company_name
  def index
    people = []
    if params.key?(:q) && params[:q].size >= 3
      people = list_entries.limit(10)
    end
    company_names = people.map do |person|
      company = person.company_name.strip
      { id: company, label: company }
    end

    render json: company_names
  end

  private

  def list_entries
    Person.select(:company_name).distinct.order(:company_name)
  end

  def authorize_action
    authorize!(:query, Person)
  end

  include Searchable

  self.search_columns = [:company_name]

  class << self

    def model_class
      Person
    end

  end

end
