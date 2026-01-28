#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class PeriodInvoiceTemplatesController < CrudController
  self.nesting = Group

  self.permitted_attrs = [:name, :start_on, :end_on,
    {
      items: [
        :id, :name, :type, :cost_center, :account, :dynamic_cost_params, :_destroy
      ]
    }]
end
