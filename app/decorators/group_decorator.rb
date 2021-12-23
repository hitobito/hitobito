# frozen_string_literal: true

#  Copyright (c) 2012-2021, Jungwacht Blauring Schweiz. This file is part of
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

  def possible_roles_without_writing_permissions
    possible_roles.reject do |r| 
      r.permissions.any? { |p| Role::Types::WRITING_PERMISSIONS.include?(p) }
    end
  end

  def to_s(*args)
    model.to_s(*args) + archived_suffix
  end

  def display_name
    model.display_name + archived_suffix
  end

  def as_typeahead
    { id: id, label: label_with_parent }
  end

  def as_quicksearch
    { id: id, label: label_with_parent, type: :group, icon: :users }
  end

  def label_with_parent
    h.safe_join([parent.to_s.presence, to_s].compact, ' > ')
  end

  def link_with_layer
    links = with_layer
            .map { |g| GroupDecorator.new(g) }
            .map { |g| h.link_to_if(can?(:show, g), g, g) }
    h.safe_join(links, ' / ')
  end

  # compute layers and concat group names using a '/'
  def name_with_layer
    group_names = with_layer
                  .map { |g| GroupDecorator.new(g) }
                  .map { |g| g.to_s }
    group_names.join(' / ')
  end

  def possible_events
    klass.event_types
  end

  delegate :possible_children, to: :klass

  def modifiable_attributes(*attributes)
    attributes = used_attributes(*attributes)
    unless can?(:modify_superior, model)
      attributes -= model.class.superior_attributes.map(&:to_s)
    end
    attributes
  end

  def modifiable?(attribute)
    modifiable_attributes(attribute).each { |_| yield }
  end

  def type_name
    klass.label
  end

  def subgroup_ids
    @subgroup_ids ||= Group.where('lft >= :lft AND rgt <= :rgt',
                                  lft: group.lft, rgt: group.rgt)
                           .pluck(:id)
  end

  def archived_class
    return nil unless model.archived?

    'is-archived'
  end

  private

  def archived_suffix
    return '' unless model.archived?

    I18n.t('group_decorator.archived_suffix')
  end
end
