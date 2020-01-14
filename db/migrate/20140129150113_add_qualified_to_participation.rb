# encoding: utf-8

#  Copyright (c) 2014, hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class AddQualifiedToParticipation < ActiveRecord::Migration[4.2]

  def up
    add_column :event_participations, :qualified, :boolean
  end

  def down
    remove_column :event_participations, :qualified
  end

end
