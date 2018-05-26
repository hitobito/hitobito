# encoding: utf-8

#  Copyright (c) 2018-2018, hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module RoleKindsHelper

  # To diplay permissions like "Schreiben auf Kommission / Lesen auf Dachverband, Verein" 
  # It needs to receive to context of layer, optionally takes the name of the group as context.
  def human_role_kind_permissions(role_kind, 
                                  layer, 
                                  group = t("activerecord.models.group", count: 1))
    out = role_kind.permissions.map do |permission|
      content_tag(:li) do 
        permission_with_tooltip(permission, layer, group)
      end
    end
    out.join().html_safe
  end

  private

  def layer_with_sublayers(layer)
    layers = Role::TypeList.new(Group.root_types.first).role_types.keys
    index = layers.find_index(layer)
    out = index ? layers[index..-1] : []
    out.join(", ")
  end

  def permission_with_tooltip(permission, layer, group)
    content_tag(:span, {rel: 'tooltip', 
                        title: human_permission_description(permission, layer, group)}) do 
      human_permission(permission, layer, group)
    end
  end

  def human_permission(permission, layer, group)
    t("activerecord.attributes.role.class.permission.#{permission}.short", 
      default: permission, 
      layer: layer, 
      layer_with_sublayers: layer_with_sublayers(layer),
      group: group)
  end

  def human_permission_description(permission, layer, group)
    t("activerecord.attributes.role.class.permission.#{permission}.description", 
      default: '', 
      layer: layer, 
      layer_with_sublayers: layer_with_sublayers(layer),
      group: group)
  end
end
