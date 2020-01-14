# encoding: utf-8

#  Copyright (c) 2012-2015, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class CreatePersonAddRequests < ActiveRecord::Migration[4.2]
  def change
    create_table :person_add_requests do |t|
      t.belongs_to :person, null: false
      t.belongs_to :requester, null: false
      t.string :type, null: false
      t.belongs_to :body, null: false
      t.string :role_type
      t.timestamp :created_at, null: false
    end

    add_index :person_add_requests, :person_id
    add_index :person_add_requests, [:type, :body_id]

    add_column :groups, :require_person_add_requests, :boolean, null: false, default: false
  end
end
