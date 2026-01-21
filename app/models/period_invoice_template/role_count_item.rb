# frozen_string_literal: true

#  Copyright (c) 2012-2026, Swiss Badminton. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class PeriodInvoiceTemplate::RoleCountItem < PeriodInvoiceTemplate::Item
  validates :role_types, presence: true

  def role_types
    dynamic_cost_parameters[:role_types] || []
  end
end
