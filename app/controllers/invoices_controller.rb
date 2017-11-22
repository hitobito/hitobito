# encoding: utf-8

#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class InvoicesController < CrudController
  self.nesting = Group
  self.permitted_attrs = [:title, :description, :invoice_items_attributes]
  self.sort_mappings = { recipient: Person.order_by_name_statement }


  def destroy
    cancelled = run_callbacks(:destroy) { entry.update(state: :cancelled) }
    set_failure_notice unless cancelled
    respond_with(entry, success: cancelled, location: group_invoices_path(parent))
  end

  private

  def list_entries
    super.includes(recipient: [:groups, :roles]).references(:recipient).list
  end

  def authorize_class
    authorize!(:create, parent.invoices.build)
  end

end
