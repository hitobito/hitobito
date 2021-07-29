#  Copyright (c) 2021, Die Mitte Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class CreatePaymentProviderConfig < ActiveRecord::Migration[6.0]
  def change
    create_table :payment_provider_configs do |t|
      t.string :payment_provider
      t.belongs_to :invoice_config
      t.integer :status, default: 0, null: false
      t.string :partner_identifier
      t.string :user_identifier
      t.string :encrypted_password
      t.text :encrypted_keys, size: :medium
      t.datetime :synced_at

      t.timestamps
    end
  end
end
