#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Person::InvoicesController < ListController
  self.sort_mappings = {recipient: "people.order_name ASC"}
  self.search_columns = [:title, :sequence_number]

  helper_method :filter_params

  private

  def list_entries
    scope = super.list
      .includes(:group)
      .where(search_conditions)
      .joins(:recipient).where(recipient: person)
      .page(params[:page]).per(50)

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

  def filter_params
    year = Time.zone.today.year
    {from: params[:from] || "1.1.#{year}", to: params[:to] || "31.12.#{year}"}
  end
end
