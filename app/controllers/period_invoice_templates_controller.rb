#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class PeriodInvoiceTemplatesController < CrudController
  self.nesting = Group

  self.permitted_attrs = [:name, :start_on, :end_on, :recipient_group_type,
    {
      items_attributes: [
        :id, :type, :name, :cost_center, :account, :vat_rate, :_destroy,
        dynamic_cost_parameters: [:unit_cost] +
          Settings.groups.period_invoice_templates.item_classes.to_h.values.flatten
      ]
    }]

  def create
    if params[:autosubmit].present?
      assign_attributes
      respond_with(entry, success: false) # force returning to the /new page
    else
      super
    end
  end

  def update
    if params[:autosubmit].present?
      assign_attributes
      respond_with(entry, success: false) # force returning to the /edit page
    else
      super
    end
  end

  def assign_attributes
    super
    entry.recipient_source ||= GroupsFilter.new
    entry.recipient_source.group_type = entry.recipient_group_type
    entry.recipient_source.active_at = entry.start_on
    entry.recipient_source.parent_id = entry.group_id
  end
end
