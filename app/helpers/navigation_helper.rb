# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module NavigationHelper

  MAIN = {
    groups:  { url: :groups_path,
               active_for: %w(groups people) },
    events:  { url: :list_events_path,
               active_for: %w(list_events) },
    courses: { url: :list_courses_path,
               active_for: %w(list_courses),
               if: ->(e) { Group.course_types.present? } },
    admin:   { url: :label_formats_path,
               active_for: %w(label_formats custom_contents event_kinds qualification_kinds),
               if: ->(e) { can?(:manage, LabelFormat) } }
  }


  def render_main_nav
    content_tag_nested(:ul, MAIN, class: 'nav') do |label, options|
      if options[:url].kind_of?(Symbol)
        options[:url] = send(options[:url])
      end
      if !options.key?(:if) || instance_eval(&options[:if])
        nav(I18n.t("navigation.#{label}"), options[:url], options[:active_for])
      end
    end
  end

  # Create a list item for navigations.
  # If alternative_paths are given, and they appear in the request url,
  # the corresponding item is active.
  # If not alternative paths are given, the item is only active if the
  # link url equals the request url.
  def nav(label, url, active_for = [])
    options = {}
    if current_page?(url) ||
       active_for.any? { |p| request.path =~ /\/?#{p}\/?/ }
      options[:class] = 'active'
    end
    content_tag(:li, link_to(label, url), options)
  end

  def tab_bar(current_path, &block)
    bar = TabBar.new(self, current_path)
    yield bar
    bar.render
  end

end

class TabBar

  attr_reader :view, :current_path

  delegate :content_tag, :link_to, :safe_join, :request, :current_page?, to: :view

  def initialize(view, current_path)
    @view = view
    @current_path = current_path
  end

    # Create a list item for navigations.
  # If alternative_paths are given, and they appear in the request url,
  # the corresponding item is active.
  # If not alternative paths are given, the item is only active if the
  # link url equals the request url.
  def tab(label, url, alt_paths = [])
    @tabs ||= []
    @tabs << [label, url, alt_paths]
  end

  def render
    return if @tabs.blank?

    active_url = find_active_tab

    content_tag(:ul, class: 'nav nav-sub') do
      safe_join(@tabs) do |label, url, _|
        content_tag(:li, link_to(label, url), class: (url == active_url ? 'active' : nil))
      end
    end
  end


  private

  # if current_page matches, this tab is active
  # if alt_paths matches, this tab is active
  # if nothing matches, first tab is active
  def find_active_tab
    active = @tabs.detect { |_, url, _| current_page?(url) }
    if active.nil?
      active = @tabs.detect do |_, _, alt_paths|
        alt_paths.any? { |p| current_path =~ /\/?#{p}\/?/ }
      end
    end
    active ? active.second : @tabs.first.second
  end
end
