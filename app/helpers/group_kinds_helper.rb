# encoding: utf-8

#  Copyright (c) 2018-2018, hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module GroupKindsHelper

  def human_group_kind_permissions(group_kind, layer)
    out = human_role_kinds(group_kind, layer)
    out << human_group_kinds(group_kind)
    out.html_safe
  end

  private

  def human_role_kinds(group_kind, layer)
    unless group_kind.roles.empty? || group_kind.layer
      out = content_tag(:h4) do
        t("activerecord.attributes.group.class.provides_roles", group: group_kind.model_name.human)
      end

      out << group_kind.roles.map do |role_kind|
        content_tag(:div) do
          out = content_tag(:h5 ) do
            [icon(:user, class: "icon-white"), role_kind.model_name.human].join(" ").html_safe
          end
          out << human_role_kind_permissions(role_kind, layer, group_kind.model_name.human)
        end
      end.join.html_safe
    end || ''
  end

  def human_group_kinds(group_kind)
    out = ''
    unless group_kind.possible_children.empty?
      out << content_tag(:h4) do
        t("activerecord.attributes.group.class.provides_groups", group: group_kind.model_name.human)
      end
      if group_kind.layer?
        out << content_tag(:p, t("activerecord.attributes.group.class.describes_layer", group: group_kind.model_name.human))
      end
      out << content_tag(:ul) do
        group_kind.possible_children.map do |child_kind|
          content_tag(:li, child_kind.model_name.human)
        end.join.html_safe
      end
    end
    out.html_safe
  end

end
