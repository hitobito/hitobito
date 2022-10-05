# frozen_string_literal: true

#  Copyright (c) 2020-2022, Stiftung für junge Auslandssschweizer. This file is part of
#  hitobito_sjas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sjas.

class AddStatusToPayments < ActiveRecord::Migration[6.1]
  def change
    add_column :payments, :status, :string
    change_column_null :payments, :invoice_id, true
  end
end
