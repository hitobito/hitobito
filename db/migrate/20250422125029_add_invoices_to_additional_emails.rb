# frozen_string_literal: true

#  Copyright (c) 2022-2025,  Eidgenössischer Jodlerverband. This file is part of
#  hitobito_cvp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class AddInvoicesToAdditionalEmails < ActiveRecord::Migration[7.1]
  def change
    add_column(:additional_emails, :invoices, :boolean, default: false)
    add_index(:additional_emails, [:contactable_id, :contactable_type], unique: true, where: "invoices = true",
      name: "index_additional_emails_on_contactable_where_invoices_true")
  end
end
