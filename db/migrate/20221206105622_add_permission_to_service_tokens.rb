# frozen_string_literal: true

#  Copyright (c) 2022, Schweizer Wanderwege. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class AddPermissionToServiceTokens < ActiveRecord::Migration[6.1]
  def change
    add_column :service_tokens, :permission, :string, null: false, default: :layer_read

    up_only do
      ServiceToken.where(layer_and_below_read: true).update_all(permission: :layer_and_below_read)
    end

    remove_column :service_tokens, :layer_and_below_read, :boolean, null: false, default: false
  end
end
