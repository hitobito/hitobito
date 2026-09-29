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

    reversible do |dir|
      dir.up do
        # Enqueued jobs with the old initialize signature would fail on the next
        # run, so drop them. They get re-enqueued correctly by the schedule job.
        Delayed::Job.where("handler LIKE '%Payments::EbicsImportJob%'").delete_all
        Delayed::Job.where("handler LIKE '%Payments::EbicsImportScheduleJob%'")
          .update_all(run_at: 1.hour.from_now)
      end
    end
  end
end
