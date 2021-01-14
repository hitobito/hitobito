#  Copyright (c) 2012-2020, CVP Schweiz. This file is part of
#  hitobito_cvp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class AddSubscriptionTags < ActiveRecord::Migration[6.0]
  def up
    create_table :subscription_tags do |t|
      t.boolean :excluded

      t.references :subscription, foreign_key: true, type: :integer, null: false
      t.references :tag, foreign_key: true, type: :integer, null: false
    end
  end

  def down
    drop_table :subscription_tags
  end
end

