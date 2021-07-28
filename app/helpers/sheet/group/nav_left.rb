# encoding: utf-8
# frozen_string_literal: true

#  Copyright (c) 2014-2021 Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Sheet
  class Group
    class NavLeft

      attr_reader :entry, :sheet, :view
      delegate :content_tag, :link_to, :safe_join, :sanitize, to: :view

      def initialize(sheet)
        @sheet = sheet
        @entry = sheet.entry
        @view = sheet.view
      end

      def render
        render_upwards +
        render_header +
        content_tag(:ul, class: 'nav-left-list') do
          render_layer_groups + render_deleted_people_link + render_sub_layers
        end
      end

      private

      def groups
        @groups ||= entry.groups_in_same_layer.without_deleted.order(:lft).to_a
      end

      def layer
        @layer ||= entry.layer_group
      end

      def render_upwards
        if layer.parent_id
          parent = layer.hierarchy[-2]
          parent.use_hierarchy_from_parent(layer.hierarchy[0..-3])
          link_to(I18n.t('sheet/group.layer_upwards'),
                  active_path(parent),
                  class: 'nav-left-back')
        else
          ''
        end
      end

      def render_header
        active = layer == entry && view.request.path !~ /\/deleted_people$/
        link_to(layer, active_path(layer), class: "nav-left-title#{' is-active' if active}")
      end

      def render_layer_groups
        out = []
        stack = []
        Array(groups[1..-1]).each do |group|
          render_stacked_group(group, stack, out)
        end
        stack.size.times do
          out << "</ul>\n</li>\n"
        end
        sanitize(out.join(''), tags: %w(ul li a), attributes: %w(class id title href))
      end

      def render_stacked_group(group, stack, out)
        last = stack.last
        if last.nil? || (last.lft < group.lft && group.lft < last.rgt)
          group.use_hierarchy_from_parent(last || layer)
          render_group_item(group, stack, out)
        else
          out << "</ul>\n</li>\n"
          stack.pop
          render_stacked_group(group, stack, out)
        end
      end

      def render_group_item(group, stack, out)
        if view.can?(:show, group) && visible?(group)
          if group.leaf?
            out << group_link(group) << "</li>\n"
          else
            out << group_link(group) << "\n<ul>\n"
            stack.push(group)
          end
        end
      end

      def group_link(group)
        cls = ' class=" is-active"' if group == entry
        "<li#{cls}>" +
        link_to(group.display_name,
                active_path(group), title: group.to_s, data: { disable_with: group.display_name })
      end

      def render_deleted_people_link
        if view.can?(:index_deleted_people, layer)
          active = view.current_page?(view.group_deleted_people_path(layer.id))
          content_tag(:li, class: ('is-active' if active).to_s) do
            link_to(view.t('groups.global.link.deleted_person'),
                    view.group_deleted_people_path(layer.id))
          end
        end
      end

      def render_sub_layers
        safe_join(grouped_sub_layers) do |type, layers|
          content_tag(:li, content_tag(:span, type, class: 'divider')) +
          safe_join(layers) do |l|
            l.use_hierarchy_from_parent(layer)
            content_tag(:li, link_to(l.display_name,
                                     active_path(l),
                                     title: l.to_s,
                                     data: { disable_with: l.display_name }))
          end
        end
      end

      def grouped_sub_layers
        sub_layers.select { |g| view.can?(:show, g) }.
          group_by { |g| g.class.label_plural }
      end

      def sub_layers
        sub_layer_types = layer.possible_children.select(&:layer).map(&:sti_name)
        layer.children
             .without_deleted
             .where(type: sub_layer_types)
             .order_by_type(layer)
      end

      def active_path(group)
        renderer = sheet.active_tab.try(:renderer, view, [group])
        if renderer&.show?
          renderer.path
        else
          view.group_path(group)
        end
      end

      def visible?(group)
        @entry.hierarchy.any? { |g| g.id == group.parent_id }
      end

    end
  end
end
