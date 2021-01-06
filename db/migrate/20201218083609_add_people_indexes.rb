# frozen_string_literal: true

#  Copyright (c) 2012-2020, CVP Schweiz. This file is part of
#  hitobito_cvp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_cvp.

class AddPeopleIndexes < ActiveRecord::Migration[6.0]
  def change
    add_index(:people, :first_name)
    add_index(:people, :last_name)
  end
end
