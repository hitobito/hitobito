#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Contactables::InvoicesController < ListController
  self.sort_mappings = {recipient: "people.order_name ASC"}
  self.search_columns = [:title, :sequence_number]

  self.nesting = Group
  self.optional_nesting = Person

  private

  def list_entries
    scope = super.list
      .includes(:group)
      .where(search_conditions)
      .page(params[:page]).per(50)
    Invoice::Filter.new(params).apply(scope)
  end

  def contactable
    @contactable ||= parents.find { |p| p.is_a?(Person) } || @group
  end

  def recipient_table_name = contactable.class.table_name

  def recipient_type = contactable.class.sti_name

  def authorize_class = authorize!(:index_received_invoices, contactable)

  def parent_scope
    parent.received_invoices
  end
end
