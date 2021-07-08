# encoding: utf-8

#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Person::InvoicesController < ListController

  self.sort_mappings = { recipient: Person.order_by_name_statement }
  self.search_columns = [:title, :sequence_number]

  private

  def list_entries
    scope = Invoice.includes(:group).
      where(search_conditions).
      joins(:recipient).where(recipient: person).list

    scope = scope.page(params[:page]).per(50)
    Invoice::Filter.new(params).apply(scope)
  end

  def person
    @person ||= fetch_person
  end

  def group
    @group ||= Group.find(params[:group_id])
  end

  def authorize_class
    authorize!(:index_invoices, person)
  end

end
