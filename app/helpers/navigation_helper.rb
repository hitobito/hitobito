# encoding: utf-8

#  Copyright (c) 2012-2019, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module NavigationHelper

  MAIN = [
    { label: :groups,
      url: :groups_path,
      icon_name: 'users',
      active_for: %w(groups people),
      inactive_for: %w(/invoices invoice_articles invoice_config payment_process invoice_lists) },

    { label: :events,
      url: :list_events_path,
      icon_name: 'calendar-alt',
      active_for: %w(list_events),
      if: ->(_) { can?(:list_available, Event) } },

    { label: :courses,
      url: :list_courses_path,
      icon_name: 'book',
      active_for: %w(list_courses),
      if: ->(_) { Group.course_types.present? && can?(:list_available, Event::Course) } },

    { label: :invoices,
      url: :first_group_invoices_or_root_path,
      icon_name: 'money-bill-alt',
      if: ->(_) { current_user.finance_groups.any? },
      active_for: %w(/invoices invoice_articles invoice_config payment_process invoice_lists) },

    { label: :admin,
      url: :label_formats_path,
      icon_name: 'cog',
      active_for: %w(label_formats
                     custom_contents
                     event_kinds
                     event_kind_categories
                     qualification_kinds
                     oauth/applications
                     help_texts
                     oauth/active_authorizations
                     event_feed
                     tags
                     mailing_lists/imap_mails),
      if: ->(_) { can?(:index, LabelFormat) } }
  ]


  def render_main_nav
    content_tag_nested(:ul, MAIN, class: 'nav-left-list') do |options|
      if !options.key?(:if) || instance_eval(&options[:if])
        main_nav_section(options)
      end
    end
  end

  def main_nav_section(options)
    url = send(options[:url]) if options[:url].is_a?(Symbol)
    active = section_active?(url, options[:active_for], options[:inactive_for])
    nav(I18n.t("navigation.#{options[:label]}"), url, options[:icon_name], active,
        class: 'nav-left-section', active_class: 'active') do
      concat(sheet.render_left_nav) if sheet.left_nav?
    end
  end

  def first_group_invoices_or_root_path
    return root_path if current_user.finance_groups.blank?
    group_invoices_path(current_user.finance_groups.first)
  end

  def nav(label, url, icon_name = false, active = false, options = {})
    classes = options[:class] || ''
    active_class = options[:active_class] || 'is-active'
    if active
      classes += " #{active_class}"
    end
    content_tag(:li, class: classes) do
      navigation_text = icon(icon_name) + label
      concat(link_to(navigation_text, url, data: { disable_with: navigation_text }))
      yield if block_given? && active
    end
  end

  private

  # If alternative_paths are given, and they appear in the request url,
  # the corresponding item is active.
  # If not alternative paths are given, the item is only active if the
  # link url equals the request url.
  def section_active?(url, active_for = [], inactive_for = [])
    current_page?(url) ||
      Array(active_for).any? { |p| request.path =~ %r{/?#{p}/?} } &&
      Array(inactive_for).none? { |p| request.path =~ %r{/?#{p}/?} }
  end
end
