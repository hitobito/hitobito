# encoding: utf-8

#  Copyright (c) 2018-2018, hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module RoleKindsHelper
  def human_role_kind_permissions(role_kind)
    text = ""
    content_tag(:ul) do
      out = role_kind.permissions.map do |permission|
        content_tag(:li) do 
          permission_with_tooltip(permission)
        end
      end
      out.join().html_safe
    end
  end

  private

  def permission_with_tooltip(permission)
    content_tag(:span, {rel: 'tooltip', title: human_permission_description(permission)}) do 
      human_permission(permission)
    end
  end

  def human_permission(permission)
    t("activerecord.attributes.role.class.permission.#{permission}.short", default: permission)
  end

  def human_permission_description(permission)
    t("activerecord.attributes.role.class.permission.#{permission}.description", default: '')
  end
end

    


# -#  Copyright (c) 2012-2016, Puzzle ITC GmbH. This file is part of
# -#  hitobito and licensed under the Affero General Public License version 3
# -#  or later. See the COPYING file at the top-level directory or at
# -#  https://github.com/hitobito/hitobito.

# .accordion#roles
#   - layer_index = 0
#   - Role::TypeList.new(Group.root_types.first).each do |layer, groups|
#     .accordion-group
#       .accordion-heading
#         %a{class: 'accordion-toggle', 'data-toggle' => 'collapse', 'data-parent' => '#roles', href: "#layer_#{layer_index}"}
#           %h2= "#{t('.layer')}: #{layer} (#{groups.length} #{Group.model_name.human(count: groups.length)})"
#       .accordion-body.collapse{id: "layer_#{layer_index}"}
#         .accordion-inner
#           - groups.each do|group, roles|
#             %h3= group
#             - roles.each do |role|
#               %h4
#                 %span{rel: 'tooltip', title: "#{Role.model_name.human} (#{role.model_name})"}
#                   = icon(:user)
#                   = role.model_name.human
#               - if role.permissions.length == 0
#                 %span Keine Berechtigungen
#               %ul
#                 - role.permissions.each do |permission|
#                   %li
#                     %span{rel: 'tooltip', title: human_permission_description(permission)}
#                       = human_permission(permission)
#     - layer_index += 1
