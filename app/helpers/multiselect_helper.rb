#  Copyright (c) 2025, Schweizer Wanderwege. This file is part of
#  hitobito_sww and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

module MultiselectHelper
  def extended_all_checkbox(scope)
    count = scope.unscope(:limit).count

    content_tag(:label, class: "extended_all btn btn-link d-inline d-none") do
      check_box_tag(:extended_all, count, false, data: {ids: "all"}, class: "d-none") +
        content_tag(:span, t("global.extended_select_all", count: count))
    end
  end
end
