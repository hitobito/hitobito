# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

class CreateSelfRegistrationReasons < ActiveRecord::Migration[6.1]
  def change
    create_table :self_registration_reasons do |t|
      t.timestamps
    end

    reversible do |dir|
      dir.up do
        SelfRegistrationReason.create_translation_table! :text => {:type => :text, :null => false}
      end

      dir.down do
        SelfRegistrationReason.drop_translation_table!
      end
    end

    change_table :people, bulk: true do |t|
      t.references :self_registration_reason, foreign_key: true
      t.string :self_registration_reason_custom_text, limit: 100
    end
  end
end
