# frozen_string_literal: true

#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class AddQualificationCommentToEventParticipations < ActiveRecord::Migration[8.0]
  def change
    add_column :event_participations, :qualification_comment, :string
  end
end
