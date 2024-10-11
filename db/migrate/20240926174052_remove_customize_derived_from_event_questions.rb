# frozen_string_literal: true

#  Copyright (c) 2012-2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class RemoveCustomizeDerivedFromEventQuestions < ActiveRecord::Migration[6.1]
  def change
    remove_column :event_questions, :customize_derived, :boolean, if_exists: true
  end
end
