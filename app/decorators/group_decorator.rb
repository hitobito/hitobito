# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class GroupDecorator < ApplicationDecorator
  decorates :group
  decorates_association :contact
  decorates_association :parent, with: GroupDecorator

  include ContactableDecorator

  def prepend_complete_address(html)
    if contact
      html << "c/o #{contact}"
      html << h.tag(:br)
    end
  end

  def possible_roles
    klass.role_types.select do |type|
      # users from above cannot create non visible roles
      !type.restricted? &&
      (type.visible_from_above? || can?(:index_local_people, model))
    end
  end

  def as_typeahead
    { id: id, label: label_with_parent }
  end

  def as_quicksearch
    { id: id, label: label_with_parent, type: :group }
  end

  def label_with_parent
    h.safe_join([parent.to_s.presence, to_s].compact, ' > ')
  end

  def link_with_layer
    h.safe_join(with_layer.map { |g| h.link_to(g, g) }, ' / ')
  end

  def possible_events
    klass.event_types
  end

  def possible_children
    klass.possible_children
  end

  def modifiable_attributes(*attributes)
    attributes = used_attributes(*attributes)
    unless can?(:modify_superior, model)
      attributes -= model.class.superior_attributes.map(&:to_s)
    end
    attributes
  end

  def type_name
    klass.label
  end

end
