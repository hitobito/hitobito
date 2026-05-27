#  Copyright (c) 2026, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Event::QuestionTemplateDecorator < ApplicationDecorator
  decorates "event/question_template"

  def event_type_label
    event_type? ? event_type.constantize.model_name.human : I18n.t("global.all")
  end
end
