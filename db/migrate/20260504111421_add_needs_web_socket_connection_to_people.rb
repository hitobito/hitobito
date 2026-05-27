#  Copyright (c) 2012-2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class AddNeedsWebSocketConnectionToPeople < ActiveRecord::Migration[8.0]
  def change
    add_column :people, :needs_web_socket_connection, :boolean
  end
end
