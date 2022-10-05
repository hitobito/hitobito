# frozen_string_literal: true

#  Copyright (c) 2020-2022, Stiftung für junge Auslandssschweizer. This file is part of
#  hitobito_sjas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sjas.

class ChangeColumnQuestionOnEventQuestionTranslations < ActiveRecord::Migration[6.1]
  def up
    change_column :event_question_translations, :question, :text
  end

  def down
    change_column :event_question_translations, :question, :string
  end
end
