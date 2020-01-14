# encoding: utf-8

#  Copyright (c) 2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class CreateInvoiceArticles < ActiveRecord::Migration[4.2]
  def change
    create_table :invoice_articles do |t|
      t.string  :number
      t.string  :name,        null: false
      t.string  :description
      t.string  :category
      t.decimal :net_price,   precision: 12,  scale: 2
      t.decimal :vat_rate,    precision: 5,   scale: 2
      t.string  :cost_center
      t.string  :account

      t.timestamps null: false

      t.index :number, unique: true
    end
  end
end
