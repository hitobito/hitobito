#  Copyright (c) 2018, Schweizer Blasmusikverband. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module RoleListsHelper
  def available_role_types_checkboxes(roles)
    safe_join(roles.map { |k, v|
      content_tag(:b, k, class: "filter-toggle") +
      safe_join(v.map { |type, count|
        content_tag(:div, class: "control-group available-role-type") do
          type_checkbox(type, count)
        end
      }, "")
    }, "")
  end

  private

  def type_checkbox(type, count)
    label_tag(nil, class: "checkbox ") do
      out = check_box_tag("role[types][#{type}]", nil, true)
      out << type.constantize.label
      out << content_tag(:div, class: "role-count") {
        count.to_s
      }
      out.html_safe
    end
  end
end
