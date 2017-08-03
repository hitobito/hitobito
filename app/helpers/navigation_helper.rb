# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module NavigationHelper

  MAIN = [
    { label: :groups,
      url: :groups_path,
      icon_name: 'user',
      active_for: %w(groups people) },

    { label: :events,
      url: :list_events_path,
      icon_name: 'calendar',
      active_for: %w(list_events),
      if: ->(_) { can?(:list_available, Event) } },

    { label: :courses,
      url: :list_courses_path,
      icon_name: 'book',
      active_for: %w(list_courses),
      if: ->(_) { Group.course_types.present? && can?(:list_available, Event::Course) } },

    { label: :admin,
      url: :label_formats_path,
      icon_name: 'cog',
      active_for: %w(label_formats custom_contents event_kinds qualification_kinds),
      if: ->(_) { can?(:index, LabelFormat) } }
  ]


  def render_main_nav
    content_tag_nested(:ul, MAIN, class: 'nav-left-list') do |options|
      if !options.key?(:if) || instance_eval(&options[:if])
        url = options[:url]
        icon_name = options[:icon_name]
        url = send(url) if url.is_a?(Symbol)
        nav(I18n.t("navigation.#{options[:label]}"), url, icon_name, options[:active_for]) do
          concat(sheet.render_left_nav) if sheet.left_nav?
        end
      end
    end
  end

  # Create a list item for navigations.
  # If alternative_paths are given, and they appear in the request url,
  # the corresponding item is active.
  # If not alternative paths are given, the item is only active if the
  # link url equals the request url.
  def nav(label, url, icon_name = false, active_for = [], &block)
    options = {}
    active = current_page?(url) || active_for.any? { |p| request.path =~ %r{/?#{p}/?} }
    if active
      options[:class] = 'active'
    end
    content_tag(:li, options) do
      concat(link_to(icon(icon_name) + label, url))
      yield if block_given? && active
    end
  end
end
