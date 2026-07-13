#  Copyright (c) 2026, CEVI Regionalverband ZH-SH-GL. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

Fabricator(:event_question_visibility, class_name: "Event::QuestionVisibility") do
  question
  role_type { Event::Role::Cook.sti_name }
end
