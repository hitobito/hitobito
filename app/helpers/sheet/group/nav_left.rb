# frozen_string_literal: true

#  Copyright (c) 2014-2021 Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# rubocop:disable Rails/HelperInstanceVariable this domain-class is in the wrong directory

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
          ''.html_safe
        end
      end

      def render_header
        active = layer == entry && view.request.path !~ /\/deleted_people$/
        link_to(layer, active_path(layer), class: "nav-left-title#{' is-active' if active}")
      end

      def render_layer_groups
        out = ''.html_safe
        stack = []
        Array(groups[1..-1]).each do |group|
          render_stacked_group(group, stack, out)
        end
        stack.size.times do
          out << "</ul>\n</li>\n".html_safe
        end
        out
      end

      def render_stacked_group(group, stack, out)
        last = stack.last
        if last.nil? || (last.lft < group.lft && group.lft < last.rgt)
          group.use_hierarchy_from_parent(last || layer)
          render_group_item(group, stack, out)
        else
          out << "</ul>\n</li>\n".html_safe
          stack.pop
          render_stacked_group(group, stack, out)
        end
      end

      def render_group_item(group, stack, out)
        if view.can?(:show, group) && visible?(group)
          if group.leaf?
            out << group_link(group) << "</li>\n".html_safe
          else
            out << group_link(group) << "\n<ul>\n".html_safe
            stack.push(group)
          end
        end
      end

      def group_link(group)
        decorated = GroupDecorator.new(group)

        li = opening_li([
          ('is-active' if group == entry),
          decorated.archived_class
        ].compact)

        display_name = sanitize(decorated.display_name, tags: %w(i))
        group_name   = sanitize(decorated.to_s, tags: %w(i))

        li + link_to(display_name, active_path(group),
                     title: group_name, data: { disable_with: display_name })
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
          safe_join(layers.map { |l| GroupDecorator.new(l) }) do |l|
            l.use_hierarchy_from_parent(layer)
            content_tag(:li, class: l.archived_class) do
              link_to(l.display_name, active_path(l),
                      title: l.to_s, data: { disable_with: l.display_name })
            end
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

      def opening_li(css_classes)
        li_tag = if css_classes.any?
                   %(<li class="#{css_classes.join(' ')}">)
                 else
                   '<li>'.html_safe
                 end

        sanitize(li_tag, tags: %w(li), attributes: %w(class))
      end

    end
  end
end

# rubocop:enable Rails/HelperInstanceVariable
