# frozen_string_literal: true

#  Copyright (c) 2012-2022, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module LayoutHelper

  def render_nav?
    (current_user&.roles.present? && !current_user&.basic_permissions_only?) || current_user&.root?
  end

  # render a single button
  def action_button(label, url, icon = nil, options = {})
    if @in_button_group || options[:in_button_group]
      button(label, url, icon, options)
    else
      button_group { button(label, url, icon, options) }
    end
  end

  def button_group(&block)
    if @in_button_group
      capture(&block)
    else
      in_button_group { content_tag(:div, class: 'btn-group', &block) }
    end
  end

  def in_button_group
    @in_button_group = true
    yield
  ensure
    @in_button_group = false
  end

  def pill_dropdown_button(dropdown, ul_classes = 'float-end')
    dropdown.button_class = nil
    content_tag(:ul, class: "nav nav-pills #{ul_classes}") do
      content_tag(:li, class: 'dropdown') do
        in_button_group { dropdown.to_s }
      end
    end
  end

  def icon(name, options = {})
    name = name.to_s.dasherize

    if options.fetch(:filled, true)
      add_css_class(options, "fas fa-#{name}")
    else
      add_css_class(options, "far fa-#{name}")
    end
    content_tag(:i, '', options)
  end

  def badge(label, type = nil, tooltip = nil)
    options = { class: "badge bg-#{type || 'default'}" }
    if tooltip.present?
      options[:title] = tooltip
      options[:data] = { bs_toggle: :tooltip }
      options[:data][:bs_html] = true if strip_tags(tooltip) != tooltip
    end

    content_tag(:span, label, options)
  end

  def section(title, &block)
    render(layout: 'shared/section', locals: { title: title }, &block)
  end

  def section_table(title, collection, add_path = nil, &block)
    collection.to_a # force relation evaluation
    if add_path || collection.present?
      title = include_add_button(title, add_path) if add_path
      render(layout: 'shared/section_table',
             locals: { title: title, collection: collection, add_path: add_path },
             &block)
    end
  end

  def grouped_table(grouped_lists, column_count, &block)
    if grouped_lists.present?
      render(layout: 'shared/grouped_table',
             locals: { grouped_lists: grouped_lists, column_count: column_count },
             &block)
    else
      content_tag(:div, ti(:no_list_entries), class: 'table')
    end
  end

  def muted(text = nil, &block)
    content_tag(:span, text, class: 'muted', &block)
  end

  def value_with_muted(value, mute)
    safe_join([content_tag(:span, f(value)), muted(mute)], ' ')
  end

  def element_visible(visible)
    "display: #{visible ? 'block' : 'none'};"
  end

  def sign_out_path
    if session[:origin_user]
      group_id = current_user.primary_group_id || current_user.groups.first.id
      group_person_impersonate_path(group_id, current_user)
    else
      destroy_person_session_path
    end
  end

  def header_logo
    logo_group = closest_group_with_logo

    return image_tag(upload_url(logo_group, :logo)) if logo_group

    wagon_image_pack_tag(Settings.application.logo.image, alt: Settings.application.name)
  end

  private

  def closest_group_with_logo
    return unless @group

    @group.self_and_ancestors.includes([:logo_attachment]).reverse.find do |group|
      upload_exists?(group, :logo)
    end
  end

  def include_add_button(title, add_path)
    button = action_button(ti(:'link.add'),
                           add_path,
                           'plus',
                           class: 'btn-sm')
    safe_join([title, content_tag(:span, button, class: 'float-end')])
  end

  def button(label, url, icon_name = nil, options = {})
    disabled_msg = options.delete(:disabled)
    return disabled_button(label, disabled_msg, icon_name, options) if disabled_msg

    add_css_class options, 'btn btn-sm'
    add_css_class options, 'btn-outline-primary' unless /(^|\s)btn-(?!sm\b)/.match options[:class]
    url = url.is_a?(ActionController::Parameters) ? url.to_unsafe_h.merge(only_path: true) : url

    if url.present?
      link_to(url, options) do
        button_content(label, icon_name)
      end
    else
      content_tag(:button, button_content(label, icon_name), options)
    end
  end

  def disabled_button(label, disabled_msg, icon_name = nil, options = {})
    content_tag(:div, title: disabled_msg) do
      content_tag(:a, class: 'btn btn-sm disabled', **options) do
        button_content(label, icon_name)
      end
    end
  end

  def button_content(label, icon_name = nil)
    html = [label]
    html.unshift icon(icon_name) if icon_name
    safe_join(html, ' ')
  end

end
