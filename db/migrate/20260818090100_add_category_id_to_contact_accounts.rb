# frozen_string_literal: true

#  Copyright (c) 2012-2026, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class AddCategoryIdToContactAccounts < ActiveRecord::Migration[8.0]
  TABLES = [:additional_addresses, :additional_emails, :phone_numbers, :social_accounts]

  def change
    TABLES.each do |table|
      add_reference table, :category, foreign_key: {to_table: :contact_account_categories},
        index: true
    end
  end
end
