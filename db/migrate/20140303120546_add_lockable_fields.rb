# encoding: utf-8

#  Copyright (c) 2014, hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class AddLockableFields < ActiveRecord::Migration[4.2]
  def change
    add_column :people, :failed_attempts, :integer, default: 0
    add_column :people, :locked_at, :datetime
  end

end
