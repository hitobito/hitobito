#  Copyright (c) 2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class AddVatNumberToInvoiceConfig < ActiveRecord::Migration[4.2]
  def change
    add_column :invoice_configs, :vat_number, :string
    add_column :invoices, :vat_number, :string
  end
end
