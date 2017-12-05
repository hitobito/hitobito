# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module NavigationHelper

  MAIN = [
    { label: :groups,
      url: :groups_path,
      active_for: %w(groups people),
      inactive_for: %w(invoices invoice_articles invoice_config) },

    { label: :events,
      url: :list_events_path,
      active_for: %w(list_events),
      if: ->(_) { can?(:list_available, Event) } },

    { label: :courses,
      url: :list_courses_path,
      active_for: %w(list_courses),
      if: ->(_) { Group.course_types.present? && can?(:list_available, Event::Course) } },

    { label: :admin,
      url: :label_formats_path,
      active_for: %w(label_formats custom_contents event_kinds qualification_kinds),
      if: ->(_) { can?(:index, LabelFormat) } },

    { label: :invoices,
      url: :first_group_invoices_or_root_path,
      if: ->(_) { current_user.finance_groups.any? },
      active_for: %w(invoices invoice_articles invoice_config) }
  ]


  def render_main_nav
    content_tag_nested(:ul, MAIN, class: 'nav') do |options|
      if !options.key?(:if) || instance_eval(&options[:if])
        url = options[:url]
        url = send(url) if url.is_a?(Symbol)
        nav(I18n.t("navigation.#{options[:label]}"),
            url,
            options[:active_for],
            options[:inactive_for])
      end
    end
  end

  def first_group_invoices_or_root_path
    return root_path if current_user.finance_groups.blank?
    group_invoices_path(current_user.finance_groups.first)
  end

  # Create a list item for navigations.
  # If alternative_paths are given, and they appear in the request url,
  # the corresponding item is active.
  # If not alternative paths are given, the item is only active if the
  # link url equals the request url.
  def nav(label, url, active_for = [], inactive_for = [])
    options = {}
    if current_page?(url) ||
       Array(active_for).any? { |p| request.path =~ %r{/?#{p}/?} } &&
        Array(inactive_for).none? { |p| request.path =~ %r{/?#{p}/?} }

      options[:class] = 'active'
    end
    content_tag(:li, link_to(label, url), options)
  end

end
