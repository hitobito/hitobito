# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Export::Pdf::Participation
  class Header < Section

    def render
      bounding_box([0, cursor], width: bounds.width) do
        font_size(22) do
          shrinking_text_box heading, style: :bold, at: [0, cursor - 15], width: bounds.width - 80
        end
        image image_path, position: :right, width: 60, height: 50
        stroke_bounds
      end
    end

    private

    def heading
      [application_type, application_name, year].join(' ')
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

    def image_path
      Rails.root.join('app/assets/images/logo.png')
    end

  end
end
