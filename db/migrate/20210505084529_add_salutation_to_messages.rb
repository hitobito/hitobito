#  Copyright (c) 2012-2021, CVP Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class AddSalutationToMessages < ActiveRecord::Migration[6.0]
  def change
    add_column(:messages, :salutation, :string)
  end
end
