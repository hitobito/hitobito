# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Export::Pdf::Participation
  class Specifics < Section

    def render
      data = answers.map { |a| [a.question.question, a.answer] }

      first_page_section do
        if data.present?
          heading { text t('event.participations.specific_information'), style: :bold }
          table(data, cell_style: { border_width: 0, padding: 2 })
          move_down_line
        end

        heading { text additional_information_label, style: :bold }
      end
    end

    private

    def answers
      participation.answers.limit(8)
    end

    def additional_information_label
      t('activerecord.attributes.event/participation.additional_information')
    end
  end
end
