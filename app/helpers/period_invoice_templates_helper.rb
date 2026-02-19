# frozen_string_literal: true

#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module PeriodInvoiceTemplatesHelper
  def format_recipient_group_type(period_invoice_template)
    period_invoice_template.recipient_group_type.constantize.model_name.human(count: 2)
  end
end
