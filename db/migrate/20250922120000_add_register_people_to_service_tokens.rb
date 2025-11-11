# frozen_string_literal: true

#  Copyright (c) 2025, BdP and DPSG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class AddRegisterPeopleToServiceTokens < ActiveRecord::Migration[7.1]
  def change
    add_column(:service_tokens, :register_people, :boolean, default: false, null: false)
  end
end
