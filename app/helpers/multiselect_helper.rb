#  Copyright (c) 2025, Schweizer Wanderwege. This file is part of
#  hitobito_sww and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

module MultiselectHelper
  # for forms that do not submit via url, e.g. method get
  def hidden_list_filter_fields
    safe_join(list_filter_params.to_query.split("&").map do |pair|
      name, value = pair.split("=", 2).map { |part| CGI.unescape(part) }
      hidden_field_tag(name, value, id: nil)
    end)
  end

  def extended_all_checkbox(scope)
    content_tag(:label, class: "extended_all btn btn-link btn-sm d-inline d-none") do
      check_box_tag(:extended_all, scope.total_count, false, data: {ids: "all"}, class: "d-none") +
        content_tag(:span, t("global.extended_select_all", count: scope.total_count))
    end
  end
end
