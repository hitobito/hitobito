# frozen_string_literal: true

#  Copyright (c) 2012-2024, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module NavigationHelper
  MAIN = [ # rubocop:disable Style/MutableConstant extended in wagons
    {label: :groups,
     url: :groups_path,
     icon_name: "users",
     active_for: %w[groups people],
     inactive_for: %w[/invoices invoice_articles invoice_config payment_process invoice_lists?]},

    {label: :reportings,
     url: :hours_approval_reportings_path,
     icon_name: "list",
     active_for: %w[reportings hours_approval],
     if: ->(_) { can?(:index, Oauth:: Application) || current_user.roles.any? { |role| role.type.include?('Administrator')} }},

    {label: :hours,
     url: :approve_hours_path,
     icon_name: "clock",
     active_for: %w[hours approve],
     inactive_for: %w[/reportings?]},

    {label: :events,
     url: :list_events_path,
     icon_name: "calendar-alt",
     active_for: %w[list_events],
     if: ->(_) { can?(:list_available, Event) }},

    {label: :courses,
     url: :list_courses_path,
     icon_name: "book",
     active_for: %w[list_courses],
     if: ->(_) { Group.course_types.present? && can?(:list_available, Event::Course) }},
    
    {label: :notifications,
     url: :event_notifications_path,
     icon_name: "comments",
     if: ->(_) { can?(:index, Oauth:: Application) || current_user.roles.any? { |role| role.type.include?('Administrator')} }},

#    {label: :invoices,
#     url: :first_group_invoices_or_root_path,
#     icon_name: "money-bill-alt",
#     if: ->(_) { current_user.finance_groups.any? },
#     active_for: %w[/invoices
#       invoices/evaluations
#       invoices/by_article
#       invoice_articles
#       invoice_config
#       payment_process
#       invoice_lists?]},

    {label: :admin,
     url: :label_formats_path,
     icon_name: "cog",
     active_for: %w[self_registration_reasons
       label_formats
       custom_contents
       event_kinds
       event_kind_categories
       qualification_kinds
       oauth/applications
       help_texts
       oauth/active_authorizations
       event_feed
       tags
       hitobito_log_entries
       mailing_lists/imap_mails
       api],
     if: ->(_) { can?(:index, LabelFormat) }}
  ]

  def render_main_nav
    content_tag_nested(:ul, MAIN, class: "nav-left-list") do |options|
      if !options.key?(:if) || instance_eval(&options[:if])
        main_nav_section(options)
      end
    end
  end

  def main_nav_section(options)
    url = send(options[:url])
    active = section_active?(url, options[:active_for], options[:inactive_for])
    classes = "nav-left-section"
    classes += " active" if active
    content_tag(:li, class: classes) do
      concat(link_to(icon(options[:icon_name]) + I18n.t("navigation.#{options[:label]}"), url))
      concat(sheet.render_left_nav) if active && sheet.left_nav?
    end
  end

  def nav(label, url, active_for = [], inactive_for = [])
    options = {}
    options[:class] = "is-active" if section_active?(url, active_for, inactive_for)
    content_tag(:li, link_to(label, url), options)
  end

  private

  # If alternative_paths are given, and they appear in the request url,
  # the corresponding item is active.
  # If not alternative paths are given, the item is only active if the
  # link url equals the request url.
  def section_active?(url, active_for = [], inactive_for = [])
    current_page?(url) ||
      (Array(active_for).any? { |p| request.path =~ %r{/?#{p}/?} } &&
      Array(inactive_for).none? { |p| request.path =~ %r{/?#{p}/?} })
  end

  def first_group_invoices_or_root_path
    return root_path if current_user.finance_groups.blank?

    group_invoices_path(current_user.finance_groups.first)
  end
end
