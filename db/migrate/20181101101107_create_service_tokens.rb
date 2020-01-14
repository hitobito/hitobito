#  Copyright (c) 2018, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class CreateServiceTokens < ActiveRecord::Migration[4.2]
  def change
    create_table :service_tokens do |t|
      t.belongs_to :layer_group, null: false
      t.string     :name, null: false
      t.text       :description
      t.string     :token, null: false, unique: true
      t.datetime   :last_access
      t.boolean    :people, default: false
      t.boolean    :people_below, default: false
      t.boolean    :groups, default: false
      t.boolean    :events, default: false

      t.timestamps null: false
    end
  end
end
