class AddNeedsWebSocketConnectionToPeople < ActiveRecord::Migration[8.0]
  def change
    add_column :people, :needs_web_socket_connection, :boolean
  end
end
