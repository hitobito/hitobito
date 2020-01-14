# encoding: utf-8

#  Copyright (c) 2016, hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class AddCancelParticipationEnabledToEvent < ActiveRecord::Migration[4.2]
  def change
    add_column :events, :applications_cancelable, :boolean, default: false, null: false
  end
end
