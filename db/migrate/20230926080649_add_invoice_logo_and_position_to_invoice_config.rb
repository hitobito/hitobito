# frozen_string_literal: true

#  Copyright (c) 2021-2022, CVP Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class AddInvoiceLogoAndPositionToInvoiceConfig < ActiveRecord::Migration[6.1]
  def change
    add_column :invoice_configs, :logo_position, :string,
               null: false, default: 'disabled'
  end
end
