# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class GroupDecorator < ApplicationDecorator
  decorates :group
  decorates_association :contact
  decorates_association :parent

  include ContactableDecorator

  def prepend_complete_address(html)
    if contact
      html << "c/o #{contact}"
      html << h.tag(:br)
    end
  end

  def possible_roles
    klass.role_types.map do |type|
        # users from above cannot create external roles
      if !type.restricted &&
        (type.visible_from_above? || can?(:index_local_people, model))
        { sti_name: type.sti_name, human: type.label }
      end
    end.compact
  end

  def as_typeahead
    {id: id, label: label_with_parent}
  end

  def as_quicksearch
    {id: id, label: label_with_parent, type: :group}
  end

  def label_with_parent
    h.safe_join([parent.to_s.presence, to_s].compact, ' > ')
  end

  def possible_events
    klass.event_types
  end

  def possible_children
    klass.possible_children
  end

  def modifiable_attributes(*attributes)
    attributes = used_attributes(*attributes)
    attributes -= model.class.superior_attributes unless can?(:modify_superior, model)
    attributes
  end

  def type_name
    klass.label
  end

end
