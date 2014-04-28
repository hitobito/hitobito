# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Sheet
  class Group < Base
    self.has_tabs = true

    delegate :group_path, to: :view

    def render_breadcrumbs
      return ''.html_safe unless breadcrumbs?

      content_tag(:div, class: 'breadcrumb') do
        content_tag(:ul) do
          crumbs = breadcrumbs.reverse.collect do |crumb|
            content_tag(:li, crumb)
          end

          content_tag(:li, belongs_to) + safe_join(crumbs, divider)
        end
      end
    end

    def title
      entry.deleted? ? "#{super} #{translate(:deleted)}" : super
    end

    def has_left_nav
      true
    end

    def render_left_nav
      groups = entry.groups_in_same_layer.without_deleted.to_a
      layer = groups.first

      render_nav_upwards(layer) +
      render_nav_header(layer) +
      content_tag(:ul, class: 'nav-left-list') do
        render_nav_layer_groups(groups[1..-1]) +
        render_nav_sub_layers(layer)
      end
    end

    private

    def link_url
      group_path(entry.id)
    end

    def breadcrumbs
      entry.parent.hierarchy.collect do |g|
        link_to(g.to_s, group_path(g))
      end
    end

    def divider
      content_tag(:li, '>', class: 'divider')
    end

    def breadcrumbs?
      entry.parent_id?
    end

    def belongs_to
      translate(:belongs_to).html_safe +
        StandardHelper::EMPTY_STRING +
        StandardHelper::EMPTY_STRING
    end

    def render_nav_upwards(layer)
      if layer.parent_id
        link_to('< zu übergeordneter Ebene',
                group_path(layer.parent_id),
                class: 'nav-left-back')
      else
        ''.html_safe
      end
    end

    def render_nav_header(layer)
      content_tag(:h3, class: "nav-left-title #{'active' if layer == entry}") do
        link_to(layer, group_path(layer))
      end
    end

    def render_nav_layer_groups(groups)
      out = ''.html_safe
      stack = []
      groups.each do |group|
        last = stack.last
        if last.nil? || (last.lft < group.lft && group.lft < last.rgt)
          if group.leaf?
            out << render_nav_group(group) << '</li>'.html_safe
          else
            out << render_nav_group(group) << '<ul>'.html_safe
            stack.push(group)
          end
        else
          out << '</li></ul>'.html_safe
          stack.pop
        end
      end
      out
    end

    def render_nav_group(group)
      cls = " class=\"active\"" if group == entry
      "<li#{cls}>".html_safe +
      link_to(group, group_path(group))
    end

    def render_nav_sub_layers(layer)
      safe_join(sub_layers(layer)) do |type, layers|
        content_tag(:li, content_tag(:span, type, class: 'divider')) +
        safe_join(layers) do |l|
          content_tag(:li, link_to(l, group_path(l)))
        end
      end
    end

    def sub_layers(layer)
      sub_layer_types = layer.possible_children.select(&:layer).map(&:sti_name)
      layer.children.
            without_deleted.
            where(type: sub_layer_types).
            order_by_type(layer).
            group_by { |g| g.class.label_plural }
    end

  end
end
