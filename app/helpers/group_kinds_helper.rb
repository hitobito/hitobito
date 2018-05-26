# encoding: utf-8

#  Copyright (c) 2018-2018, hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module GroupKindsHelper

  def human_group_kind_permissions(group_kind, layer)
    out = content_tag(:h4) do
      t("activerecord.attributes.group.class.provides_roles", group: group_kind.model_name.human)
    end
    out << group_kind.roles.map do |role_kind|
      content_tag(:div) do
        out = content_tag(:h5 ) do 
          [icon(:user, class: "icon-white"), role_kind.model_name.human].join(" ").html_safe
        end
        out << content_tag(:ul) do 
          human_role_kind_permissions(role_kind, layer, group_kind.model_name.human)
        end
      end
    end.join.html_safe
  end
end
