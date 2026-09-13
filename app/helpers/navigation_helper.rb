# frozen_string_literal: true

#  Copyright (c) 2012-2026, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module NavigationHelper
  MAIN = [
    {label: :groups,
     url: :groups_path,
     icon_name: "users",
     active_for: %w[groups people],
     inactive_for: %w[invoices invoice_articles invoice_config payment_process payments
       period_invoice_templates invoice_runs?]},

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

    {label: :invoices,
     url: :first_group_invoices_or_root_path,
     icon_name: "money-bill-alt",
     if: ->(_) { can?(:index, Invoice) },
     active_for: %w[invoices
       invoices/evaluations
       invoices/by_article
       invoice_articles
       invoice_config
       payment_process
       period_invoice_templates
       payments
       invoice_runs?]},

    {label: :admin,
     url: :admin_path,
     icon_name: "cog",
     active_for: ->(_) { admin_active_for_paths },
     if: ->(_) { can?(:update_settings, current_person) }}
  ]

  ADMIN_GROUPS = {
    main: {
      heading: "admins.show.main",
      items: [
        Item.new(model: LabelFormat, path: :label_formats_path),
        Item.new(model: CustomContent, path: :custom_contents_path),
        Item.new(model: HelpText, path: :help_texts_path),
        Item.new(model: Oauth::Application, path: :oauth_applications_path),
        Item.new(label: "navigation.admin/oauth_authorizations",
          path: :oauth_active_authorizations_path,
          if: ->(_) { current_user.oauth_applications.exists? }),
        Item.new(model: ActsAsTaggableOn::Tag, path: :tags_path),
        FeatureGate.if("personal_documents") do
          Item.new(model: PersonalDocumentLabel, path: :personal_document_labels_path)
        end
      ].compact_blank
    },
    info: {
      heading: "admins.show.info",
      items: [
        Item.new(label: "json_api", path: :api_path),
        Item.new(label: "navigation.imap_mails",
          path: ->(_) { imap_mails_path(mailbox: "inbox") },
          active_for: "mails/imap",
          if: ->(_) { can?(:manage, Imap::Mail) }),
        Item.new(label: "navigation.admin/event_feed",
          path: :event_feed_path,
          if: ->(_) { can?(:update, current_user) }),
        Item.new(label: "hitobito_log_entries.index.title",
          path: :hitobito_log_entries_path,
          if: ->(_) { can?(:index, HitobitoLogEntry) })
      ]
    },
    events: {
      heading: "admins.show.events",
      items: [
        Item.new(model: Event::Kind, path: :event_kinds_path),
        Item.new(model: Event::KindCategory, path: :event_kind_categories_path),
        Item.new(model: QualificationKind, path: :qualification_kinds_path)
      ]
    },
    people: {
      heading: "admins.show.people",
      items: [
        Item.new(model: SelfRegistrationReason, path: :self_registration_reasons_path),
        Item.new(model: ContactAccountCategory, path: :contact_account_categories_path)
      ]
    }
  }

  # Unfiltered by visibility on purpose as evaluated on every page and only affects highlighting
  def admin_active_for_paths
    ADMIN_GROUPS.values.flat_map { |group| group[:items] }
      .map { |item| item.active_for(self) }
  end

  def admin_current_group_key
    ADMIN_GROUPS.find do |_key, group|
      group[:items].any? { |item| item.visible?(self) && item.current?(self) }
    end&.first
  end

  def admin_groups_by_heading
    ADMIN_GROUPS.sort_by { |_key, group| t(group[:heading]) }
  end

  # A group's visible items, sorted by their translated label.
  def admin_group_items(group)
    group[:items].select { |item| item.visible?(self) }
      .sort_by { |item| item.label(self) }
  end

  def render_main_nav
    content_tag_nested(:ul, MAIN, class: "nav-left-list") do |options|
      if !options.key?(:if) || instance_eval(&options[:if])
        main_nav_section(options)
      end
    end
  end

  def main_nav_section(options)
    url = send(options[:url])
    active = section_active?(url, resolve_active_for(options[:active_for]), options[:inactive_for])
    classes = "nav-left-section"
    classes += " active" if active
    content_tag(:li, class: classes) do
      concat(link_to(icon(options[:icon_name]) + I18n.t("navigation.#{options[:label]}"), url))
      concat(sheet.render_left_nav) if active && sheet.left_nav?
    end
  end

  def resolve_active_for(active_for)
    active_for.is_a?(Proc) ? instance_eval(&active_for) : active_for
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
      (Array(active_for).any? { |p| request.path =~ %r{/#{p}/?} } &&
      Array(inactive_for).none? { |p| request.path =~ %r{/#{p}/?} })
  end

  def first_group_invoices_or_root_path
    return root_path if current_ability.user_finance_layer_ids.blank?

    group_invoices_path(current_ability.user_finance_layer_ids.first)
  end
end
