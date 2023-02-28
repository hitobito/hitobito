# frozen_string_literal: true

#  Copyright (c) 2017, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class MigrateInvoiceConfigsToQr < ActiveRecord::Migration[6.1]
  def up
    execute 'UPDATE invoice_configs SET payment_slip="qr"'
    change_column :invoice_configs, :payment_slip, :string, default: :qr
  end

  def down
    change_column :invoice_configs, :payment_slip, :string, default: :ch_es
  end
end
