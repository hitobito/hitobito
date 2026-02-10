#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class PeriodInvoiceTemplatesController < CrudController
  self.nesting = Group

  self.permitted_attrs = [:name, :start_on, :end_on,
    {
      items_attributes: [
        :id, :type, :name, :cost_center, :account, :_destroy,
        dynamic_cost_parameters: [:unit_cost] +
          Settings.groups.period_invoice_templates.item_classes.to_h.values.flatten
      ]
    }]
end
