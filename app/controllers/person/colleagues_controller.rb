# encoding: utf-8

#  Copyright (c) 2017, Dachverband Schweizer Jugendparlamente. This file is
#  part of hitobito and licensed under the Affero General Public License
#  version 3 or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Person::ColleaguesController < ApplicationController

  before_action :authorize_action

  decorates :group, :person, :colleagues

  respond_to :html

  def index
    @colleagues = list_entries
    respond_with(@colleagues)
  end

  private

  def list_entries
    return Person.none.page(1) unless person.company_name?

    Person.
      where(company_name: person.company_name).
      preload_public_accounts.
      preload_groups.
      joins(:roles).
      order_by_name.
      distinct.
      page(params[:page])
  end

  def person
    @person ||= group.people.find(params[:id])
  end

  def group
    @group ||= Group.find(params[:group_id])
  end

  def authorize_action
    authorize!(:show, person)
  end

  def model_class
    Person
  end

  include Sortable

  self.sort_mappings = {
    roles: [Person.order_by_role_statement].concat(Person.order_by_name_statement)
  }

end
