# frozen_string_literal: true

# Copyright (c) 2012-2022, Hitobito AG. This file is part of
# hitobito and licensed under the Affero General Public License version 3
# or later. See the COPYING file at the top-level directory or at
# https://github.com/hitobito/hitobito.

class AddSupportsApplicationsToEvents < ActiveRecord::Migration[6.1]
  def change
    add_column :events, :supports_applications, :boolean, null: false, default: true

    connection = ActiveRecord::Base.connection
    sql = <<-SQL
        UPDATE events
        SET supports_applications = true
        WHERE id IN
        (
          SELECT id FROM events WHERE type = 'Event::Course'
        )
    SQL
    connection.execute(sql)
  end
end
