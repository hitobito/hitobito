# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

class ChangeMailingListsSubscribable < ActiveRecord::Migration[6.1]
  def change
    Person.transaction do
      add_column(:mailing_lists, :subscribable_for, :string, default: :nobody, null: false)
      add_column(:mailing_lists, :subscribable_mode, :string)
      reversible do |dir|
        dir.up do
          execute "UPDATE mailing_lists SET subscribable_for = 'anyone' WHERE subscribable = true"
          execute "UPDATE mailing_lists SET subscribable_mode = 'opt_out' WHERE subscribable = true"
        end
        dir.down do
          execute "UPDATE mailing_lists SET subscribable = true WHERE subscribable_for = 'anyone'"
        end
      end
      remove_column(:mailing_lists, :subscribable, :boolean, default: :false)
    end
  end
end
