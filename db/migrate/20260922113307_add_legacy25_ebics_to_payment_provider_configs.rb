# frozen_string_literal: true

#  Copyright (c) 2026, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class AddLegacy25EbicsToPaymentProviderConfigs < ActiveRecord::Migration[8.0]
  def change
    add_column :payment_provider_configs, :legacy_25_ebics, :boolean, default: true, null: false

    add_index :payment_provider_configs,
      [:invoice_config_id, :payment_provider, :legacy_25_ebics],
      unique: true,
      name: "index_payment_provider_configs_on_config_provider_and_legacy"
  end
end
