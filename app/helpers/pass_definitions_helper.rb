#  Copyright (c) 2025, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module PassDefinitionsHelper
  def format_pass_definition_name(pass_definition)
    content_tag(:strong) do
      if can?(:show, pass_definition)
        link_to(
          pass_definition.name,
          group_pass_definition_path(pass_definition.owner, pass_definition)
        )
      else
        pass_definition.name
      end
    end
  end

  def format_pass_definition_background_color(pass_definition)
    color = pass_definition.background_color
    swatch = content_tag(:span, "", class: "color-swatch",
      style: "background:#{ERB::Util.html_escape(color)}")
    safe_join([swatch, color])
  end
end
