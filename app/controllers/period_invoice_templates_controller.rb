#  Copyright (c) 2026, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class PeriodInvoiceTemplatesController < CrudController
  self.nesting = Group

  self.permitted_attrs = [:name, :start_on, :end_on]
end
