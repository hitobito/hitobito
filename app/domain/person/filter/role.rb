# encoding: utf-8

#  Copyright (c) 2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Person::Filter::Role < Person::Filter::Base

  self.permitted_args = [:role_type_ids, :role_types]

  def initialize(attr, args)
    super
    initialize_role_types
  end

  def apply(scope)
    scope.where(roles: { type: args[:role_types] })
  end

  def blank?
    args[:role_type_ids].blank?
  end

  def to_hash
    { role_types: args[:role_types] }
  end

  def to_params
    { role_type_ids: args[:role_type_ids].join(ID_URL_SEPARATOR) }
  end

  private

  def initialize_role_types
    classes = role_classes
    args[:role_type_ids] = classes.map(&:id)
    args[:role_types] = classes.map(&:sti_name)
  end

  def role_classes
    if args[:role_types].present?
      role_classes_from_types
    else
      Role.types_by_ids(id_list(:role_type_ids))
    end
  end

  def role_classes_from_types
    map = Role.all_types.each_with_object({}) { |r, h| h[r.sti_name] = r }
    args[:role_types].map { |t| map[t] }.compact
  end

end
