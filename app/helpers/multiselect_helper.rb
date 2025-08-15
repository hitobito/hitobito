#  Copyright (c) 2025, Schweizer Wanderwege. This file is part of
#  hitobito_sww and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

module MultiselectHelper
  def extended_all_checkbox(scope, max_pages = 10)
    return unless scope.total_pages <= max_pages && scope.first.respond_to?(:id)
    ids = scope.unscope(:limit).pluck(:id)
    content_tag(:label, class: "extended_all btn btn-link d-inline d-none") do
      check_box_tag(:extended_all, ids.count, false, data: {ids: JSON.generate(ids)},
        class: "d-none") +
        content_tag(:span, t("global.extended_select_all", count: ids.count))
    end
  end
end
