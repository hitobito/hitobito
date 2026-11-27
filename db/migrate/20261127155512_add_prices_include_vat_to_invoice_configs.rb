#  Copyright (c) 2026, florist.ch. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class AddPricesIncludeVatToInvoiceConfigs < ActiveRecord::Migration[8.1]
  def change
    add_column :invoice_configs, :prices_include_vat, :boolean, null: false, default: false
  end
end
