#  frozen_string_literal: true

#  Copyright (c) 2021, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class AddDeviseConfirmableToPerson < ActiveRecord::Migration[6.1]
  # Note: We can't use change, as User.update_all will fail in the down migration
  def up
    add_column :people, :confirmation_token, :string
    add_column :people, :confirmed_at, :datetime
    add_column :people, :confirmation_sent_at, :datetime
    add_column :people, :unconfirmed_email, :string # Only if using reconfirmable
    add_index :people, :confirmation_token, unique: true
    Person.reset_column_information # Need for some types of updates, but not for update_all.
    # To avoid a short time window between running the migration and updating all existing
    # people as confirmed, do the following
    Person.update_all confirmed_at: DateTime.now
    # All existing user accounts should be able to log in after this.
  end

  def down
    remove_index :people, :confirmation_token
    remove_columns :people, :confirmation_token, :confirmed_at, :confirmation_sent_at
    remove_columns :people, :unconfirmed_email # Only if using reconfirmable
  end
end
