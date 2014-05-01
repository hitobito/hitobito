# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
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

  def icon(name)
    content_tag(:i, '', class: "icon icon-#{name}")
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
    safe_join([content_tag(:span, f(value), class: 'nowrap'), muted(mute)], ' ')
  end

  def element_visible(visible)
    "display: #{visible ? 'block' : 'none'};"
  end

  private

  def include_add_button(title, add_path)
    button = action_button(ti(:'link.add_without_model'),
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
