# encoding: utf-8

#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Person::InvoicesController < InvoicesController

  private

  def list_entries
    scope = Invoice.
      includes(:group, recipient: [:groups, :roles]).
      joins(:recipient).where(recipient: person).list

    scope = scope.page(params[:page]).per(50)
    Invoice::Filter.new(params).apply(scope)
  end

  def person
    @person ||= group.people.find(params[:id])
  end

  def group
    @group ||= Group.find(params[:group_id])
  end

  def authorize_class
    authorize!(:index_invoices, person)
  end

end
