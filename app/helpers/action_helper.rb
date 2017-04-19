# encoding: utf-8

#  Copyright (c) 2012-2015, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module ActionHelper

  # Standard button action to the show page of a given record.
  # Uses the current record if none is given.
  def button_action_show(path = nil, options = {})
    path ||= path_args(entry)
    action_button ti(:"link.show"), path, 'zoom-in', options
  end

  # Standard button action to the edit page of a given record.
  # Uses the current record if none is given.
  def button_action_edit(path = nil, options = {})
    path ||= path_args(entry)
    action_button ti(:"link.edit"),
                  path.is_a?(String) ? path : edit_polymorphic_path(path),
                  'edit',
                  options
  end

  # Standard button action to the destroy action of a given record.
  # Uses the current record if none is given.
  def button_action_destroy(path = nil, options = {})
    path ||= path_args(entry)
    options[:data] ||= {}
    options[:data].reverse_merge!(confirm: ti(:confirm_delete), method: :delete)
    action_button ti(:"link.delete"), path, 'trash', options
  end

  # Standard button action to the list page.
  # Links to the current model_class if no path is given.
  def button_action_index(path = nil, url_options = { returning: true }, options = {})
    path ||= path_args(model_class)
    action_button ti(:"link.list"),
                  path.is_a?(String) ? path : polymorphic_path(path, url_options),
                  'list',
                  options
  end

  # Standard button action to the new page.
  # Links to the current model_class if no path is given.
  def button_action_add(path = nil, url_options = {}, options = {})
    path ||= path_args(model_class)
    action_button ti(:"link.add"),
                  path.is_a?(String) ? path : new_polymorphic_path(path, url_options),
                  'plus',
                  options
  end

  # Standard link action to the edit page of a given record.
  # Uses the current record if none is given.
  def link_action_edit(path = nil)
    path ||= path_args(entry)
    link_to(icon(:edit),
            path.is_a?(String) ? path : edit_polymorphic_path(path),
            title: ti(:"link.edit"),
            alt: ti(:"link.edit"))
  end

  # Standard link action to the destroy action of a given record.
  # Uses the current record if none is given.
  def link_action_destroy(path = nil, label = icon(:trash))
    path ||= path_args(entry)
    link_to label,
            path,
            class: 'action',
            title: ti(:"link.delete"),
            alt: ti(:"link.delete"),
            data: { confirm: ti(:confirm_delete),
                    method: :delete }
  end

  private

  # If a block is given, call it to get the path for the current row entry.
  # Otherwise, return the standard path args.
  def action_path(e)
    block_given? ? yield(e) : path_args(e)
  end

end
