#  Copyright (c) 2012-2021, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class PersonDecorator < ApplicationDecorator
  decorates :person

  class_attribute :login_status_icons, default: {
    no_login: "user-slash",
    password_email_sent: "user-clock",
    login: "user-check",
    two_factors: "user-shield",
    status_off: "minus-circle",
    blocked: "user-lock",
    not_blocked: "lock-open"
  }

  include ContactableDecorator

  def as_typeahead
    {id: id, label: h.h(full_label)}
  end

  def as_quicksearch
    {id: id, label: h.h(full_label), type: :person, icon: :user}
  end

  def as_typeahead_with_address
    {id: id, label: h.h(name_with_address)}
  end

  def full_label
    label = to_s
    label << ", #{town}" if town?
    if company?
      name = full_name
      label << " (#{name})" if name.present?
    elsif birthday
      label << " (#{birthday.year})"
    end
    label
  end

  def birth_year
    birthday.year if birthday.present?
  end

  def name_with_address
    label = to_s
    details = [zip_code, town].compact.join(" ")
    label << " (#{details})" if details.present?
    label
  end

  def address_name
    if company?
      company_address_name
    else
      private_address_name
    end
  end

  def additional_name
    if company?
      full_name
    else
      company_name
    end
  end

  def picture_full_url
    pic_url = if picture.attached?
      h.url_for(picture)
    else
      h.asset_pack_path("media/images/#{picture_default}")
    end

    if pic_url.respond_to?(:url)
      pic_url.url
    elsif h.request
      h.request.protocol + h.request.host_with_port + pic_url
    else
      pic_url
    end
  end

  def layer_group_label
    group = person.layer_group
    h.link_to(group, h.group_path(group)) if group
  end

  def roles
    super.reject(&:archived?)
  end

  def current_roles_grouped
    @current_roles_grouped ||= roles_grouped(scope: person.roles)
  end

  def future_roles_grouped
    @future_roles_grouped ||= roles_grouped(scope: person.roles.future)
  end

  def roles_list(group = nil, multiple_groups = false)
    roles_short(group, multiple_groups, edit: false)
  end

  # render a list of all roles
  # if a group is given, only render the roles of this group
  def roles_short(group = nil, multiple_groups = false, edit: true)
    functions_short(filtered_roles(group, multiple_groups), multiple_groups, edit: edit)
  end

  def filtered_roles(group = nil, multiple_groups = false)
    if multiple_groups
      filtered_functions(roles.to_a, :group).select { |r| group.subgroup_ids.include? r.group_id }
    else
      filtered_functions(roles.to_a, :group, group)
    end
  end

  def latest_qualifications_uniq_by_kind
    qualifications
      .includes(:person, qualification_kind: :translations)
      .order_by_date
      .group_by(&:qualification_kind).values.map(&:first)
  end

  def pending_applications
    @pending_applications ||=
      Event::ApplicationDecorator.decorate_collection(event_queries.pending_applications)
  end

  def upcoming_events
    @upcoming_events ||= EventDecorator.decorate_collection(event_queries.upcoming_events)
  end

  def upcoming_participations
    @upcoming_participations ||=
      Event::ParticipationDecorator.decorate_collection(event_queries.upcoming_participations)
  end

  def last_role_new_link(group)
    path = h.new_group_role_path(restored_group(group), role_id: last_role.id)
    role_popover_link(path, "role_#{last_role.id}", "popover_toggler ps-1")
  end

  def last_role
    @last_role ||= last_non_restricted_role
  end

  def restored_group(default_group)
    last_role.group.deleted_at? ? default_group : last_role.group
  end

  # returns roles grouped by their group
  def roles_grouped(scope: roles)
    scope.each_with_object(Hash.new { |h, k| h[k] = [] }) do |role, memo|
      memo[role.group] << role
    end
  end

  def roles_for_oauth
    object.roles.includes(:group).collect(&:decorate).collect(&:for_oauth)
  end

  def login_status_icon(login_status = object.login_status)
    h.icon(
      login_status_icons.fetch(login_status),
      login_status_icon_options(login_status)
    )
  end

  private

  def login_status_icon_options(login_status)
    {title: I18n.t("people.login_status.#{login_status}")}
  end

  def event_queries
    Person::EventQueries.new(object)
  end

  def company_address_name
    html = content_tag(:strong, company_name)
    if full_name.present?
      html << br
      html << full_name
    end
    html
  end

  def private_address_name
    html = "".html_safe
    if company_name.present?
      html << company_name
      html << br
    end
    html << content_tag(:strong, to_s)
  end

  def filtered_functions(functions, scope_method, scope = nil)
    if scope
      functions.select { |r| r.send(:"#{scope_method}_id") == scope.id }
    else
      functions
    end
  end

  def functions_short(functions, multiple_groups, edit: true)
    h.safe_join(functions) do |f|
      content_tag(:p, function_short(f, multiple_groups, edit: edit), id: h.dom_id(f))
    end
  end

  def function_short(function, multiple_groups, edit: true)
    html = [function.to_s]
    html << h.muted(h.safe_join(function.group.with_layer, " / ")) if multiple_groups
    html << popover_edit_link(function) if edit && h.can?(:update, function)
    h.safe_join(html, " ")
  end

  def popover_edit_link(function)
    path = h.edit_group_role_path(function.group, function)
    role_popover_link(path, nil, "ps-1")
  end

  def role_popover_link(path, html_id = nil, html_classes = "")
    content_tag(:span, class: html_classes, id: html_id) do
      h.link_to(h.icon(:edit),
        path,
        title: h.t("global.link.edit"),
        remote: true)
    end
  end
end
