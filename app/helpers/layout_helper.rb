#  Copyright (c) 2012-2019, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module LayoutHelper

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

  def pill_dropdown_button(dropdown, ul_classes = 'pull-right')
    dropdown.button_class = nil
    content_tag(:ul, class: "nav nav-pills #{ul_classes}") do
      content_tag(:li, class: 'dropdown') do
        in_button_group { dropdown.to_s }
      end
    end
  end

  def icon(name, options = { outline: false })
    if options[:outline]
      add_css_class(options, "far fa-#{name}")
    else
      add_css_class(options, "fa fa-#{name}")
    end
    content_tag(:i, '', options)
  end

  def badge(label, type = nil, tooltip = nil)
    options = { class: "badge badge-#{type || 'default'}" }
    if tooltip.present?
      options.merge!(rel: :tooltip,
                     'data-html' => 'true',
                     title: tooltip)
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

  def header_logo_css
    return unless @group

    logo_group = @group.self_and_ancestors.find do |group|
      group.logo.present?
    end

    return unless logo_group

    selector = 'header.logo a.logo-image'

    content_tag 'style' do
      "#{selector} { background-image: url(#{asset_path(logo_group.logo)}); }"
    end
  end

  private

  def include_add_button(title, add_path)
    button = action_button(ti(:'link.add'),
                           add_path,
                           'plus',
                           class: 'btn-small')
    safe_join([title, content_tag(:span, button, class: 'pull-right')])
  end

  def button(label, url, icon_name = nil, options = {})
    add_css_class options, 'btn'
    link_to(url, options) do
      html = [label]
      html.unshift icon(icon_name) if icon_name
      safe_join(html, ' ')
    end
  end

end
