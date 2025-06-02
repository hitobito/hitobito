# frozen_string_literal: true

#  Copyright (c) 2012-2025, Swiss Badminton. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class InvoiceItem::FixedFee < InvoiceItem
  attr_readonly :name, :dynamic_cost_parameters

  def name
    I18n.t(read_attribute(:name), scope: "fixed_fees.#{dynamic_cost_parameters[:fixed_fees]}")
  end
end
