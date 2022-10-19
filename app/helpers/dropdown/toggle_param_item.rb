# frozen_string_literal: true

#  Copyright (c) 2022, Die Mitte Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Dropdown
  class ToggleParamItem

    def initialize(template, param_name, label, checked: false)
      @template = template
      @param_name = param_name
      @label = label
      @checked = checked
    end

    def render(template)
      template.content_tag(:li) do
        template.link_to('#', class: "toggle-param") do
          render_checkbox(template)
        end
      end
    end

    def render_checkbox(template)
      template.content_tag(:div, class: 'checkbox') do
        template.content_tag(:label, for: @id) do
          template.safe_join([
            template.check_box_tag(@param_name, '1', @checked, 'data-toggle-param-name': @param_name),
            @label
          ].compact)
        end
      end
    end
  end
end
