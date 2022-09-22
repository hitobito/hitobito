# frozen_string_literal: true

#  Copyright (c) 2020-2022, Stiftung für junge Auslandssschweizer. This file is part of
#  hitobito_sjas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sjas.

# Since the DB column is a varchar and previously it was declared as enum in the model,
# it saved the enum indexes as strings e.g "1", "2", "3"...
# Because we want to convert it to an i18n_enum, we now have to migrate those payment states
class MigratePaymentsStatusToCorrectFormat < ActiveRecord::Migration[6.1]
  def up
    relevant_payments.find_each do |payment|
      payment.update_attribute(:status, up_mapping[payment.status])
    end
  end

  def down
    relevant_payments.find_each do |payment|
      payment.update_attribute(:status, down_mapping[payment.status])
    end
  end

  private

  def relevant_payments
    Payment.where('status IS NOT NULL')
  end

  def up_mapping
    @up_mapping ||= %w(ebics_imported
                       xml_imported
                       manually_created
                       without_invoice).map.with_index do |i18n_key, index|
      [index.to_s, i18n_key]
    end.to_h
  end

  def down_mapping
    @down_mapping ||= up_mapping.to_a.map(&:reverse).to_h
  end
end
