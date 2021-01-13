# frozen_string_literal: true
#
#  Copyright (c) 2012-2021, CVP Schweiz. This file is part of
#  hitobito_cvp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#
#  https://github.com/hitobito/hitobito

class AddInvoiceListsToMessages < ActiveRecord::Migration[6.0]
  def change
    change_table :messages do |t|
      t.text :invoice_attributes
      t.belongs_to :invoice_list
    end

    change_table :message_recipients do |t|
      t.belongs_to :invoice
    end
  end
end
