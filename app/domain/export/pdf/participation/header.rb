# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Export::Pdf::Participation
  class Header < Section

    def render
      bounding_box([0, cursor], width: bounds.width, height: 40) do
        font_size(20) do
          shrinking_text_box heading, style: :bold, width: bounds.width - 80
        end
        render_image
      end
    end

    private

    def heading
      [application_type, year].join(' ')
    end

    def application_type
      [event.class.model_name.human, Event::Application.model_name.human.downcase].join
    end

    def application_name
      Settings.application.name
    end

    def year
      event.dates.map(&:start_at).map(&:year).min
    end

    def render_image
    end

  end
end
