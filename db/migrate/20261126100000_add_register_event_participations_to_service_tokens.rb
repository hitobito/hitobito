# frozen_string_literal: true

#  Copyright (c) 2026, Berner Fachhochschule. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class AddRegisterEventParticipationsToServiceTokens < ActiveRecord::Migration[8.0]
  def change
    add_column(:service_tokens, :register_event_participations, :boolean,
      default: false, null: false)
  end
end
