# encoding: utf-8

#  Copyright (c) 2014, hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class CreateAdditionalEmails < ActiveRecord::Migration[4.2]
  def change
    create_table :additional_emails do |t|
      t.belongs_to :contactable, polymorphic: true, null: false
      t.string :email, null: false
      t.string :label
      t.boolean :public, null: false, default: true
      t.boolean :mailings, null: false, default: true
    end
    add_index :additional_emails, [:contactable_id, :contactable_type]
  end
end
