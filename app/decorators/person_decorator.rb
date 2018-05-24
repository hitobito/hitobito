# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class PersonDecorator < ApplicationDecorator

  decorates :person

  include ContactableDecorator

  def as_typeahead
    { id: id, label: h.h(full_label) }
  end

  def as_quicksearch
    { id: id, label: h.h(full_label), type: :person }
  end

  def as_typeahead_with_address
    { id: id, label: h.h(name_with_address) }
  end

  def full_label
    label = to_s
    label << ", #{town}" if town?
    if company?
      name = full_name
      label << " (#{name})" if name.present?
    else
      label << " (#{birthday.year})" if birthday
    end
    label
  end

  def name_with_address
    label = to_s
    details = [zip_code, town].compact.join(' ')
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
    if h.request
      h.request.protocol + h.request.host_with_port + picture.url
    else
      picture.url
    end
  end

  def layer_group_label
    group = person.layer_group
    h.link_to(group, h.group_path(group)) if group
  end

  # render a list of all roles
  # if a group is given, only render the roles of this group
  def roles_short(group = nil)
    functions_short(filtered_roles(group), group)
  end

  def filtered_roles(group = nil)
    filtered_functions(roles.to_a, :group, group)
  end

  # returns roles grouped by their group
  def roles_grouped
    roles.each_with_object(Hash.new { |h, k| h[k] = [] }) do |role, memo|
      memo[role.group] << role
    end
  end

  def latest_qualifications_uniq_by_kind
    qualifications.
      includes(:person, qualification_kind: :translations).
      order_by_date.
      group_by(&:qualification_kind).values.map(&:first)
  end

  def pending_applications
    @pending_applications ||=
      Event::ApplicationDecorator.decorate_collection(event_queries.pending_applications)
  end

  def upcoming_events
    @upcoming_events ||= EventDecorator.decorate_collection(event_queries.upcoming_events)
  end

  def relations
    @relations ||= relations_to_tails.list.includes(tail: [:groups, :roles])
  end

  def last_role_new_link(group)
    path = h.new_group_role_path(restored_group(group), role_id: last_role.id)
    role_popover_link(path, "role_#{last_role.id}")
  end

  def last_role
    @last_role ||= last_non_restricted_role
  end

  def restored_group(default_group)
    last_role.group.deleted_at? ? default_group : last_role.group
  end

  private

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
    html = ''.html_safe
    if company_name.present?
      html << company_name
      html << br
    end
    html << content_tag(:strong, to_s)
  end

  def filtered_functions(functions, scope_method, scope = nil)
    if scope
      functions.select { |r| r.send("#{scope_method}_id") == scope.id }
    else
      functions
    end
  end

  def functions_short(functions, scope = nil)
    h.safe_join(functions) do |f|
      content_tag(:p, function_short(f, scope), id: h.dom_id(f))
    end
  end

  def function_short(function, scope = nil)
    html = [function.to_s]
    html << h.muted(h.safe_join(function.group.with_layer, ' / ')) if scope.nil?
    html << popover_edit_link(function) if h.can?(:update, function)
    h.safe_join(html, ' ')
  end

  def popover_edit_link(function)
    path = h.edit_group_role_path(function.group, function)
    role_popover_link(path)
  end

  def role_popover_link(path, html_id = nil)
    content_tag(:span, style: 'padding-left: 10px', id: html_id) do
      h.link_to(h.icon(:edit),
                path,
                title: h.t('global.link.edit'),
                remote: true)
    end
  end
end
