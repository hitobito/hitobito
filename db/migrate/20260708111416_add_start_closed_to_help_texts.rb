# frozen_string_literal: true

#  Copyright (c) 2026, CEVI Regionalverband ZH-SH-GL. This file is part of
#  hitobito_cevi and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class AddStartClosedToHelpTexts < ActiveRecord::Migration[8.0]
  def change
    add_column(:help_texts, :start_open, :boolean, default: false, null: false)
  end
end
