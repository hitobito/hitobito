# frozen_string_literal: true

#  Copyright (c) 2012-2021, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Export::Pdf::Participation
  class Specifics < Section
    def render
      data = answers.map { |a| [strip_tags(a.question.question), a.answer] }

      if data.present?
        with_header(I18n.t('event.participations.application_answers')) do
          table(data, cell_style: { border_width: 0, padding: 2 })
        end
      end

      with_header(additional_information_label) do
        text(participation.additional_information.to_s.strip.presence || '-')
      end
    end

    private

    def answers
      participation.answers.
        joins(:question).
        includes(:question).
        where(event_questions: { admin: false })
    end

    def additional_information_label
      I18n.t('activerecord.attributes.event/participation.additional_information')
    end
  end
end
