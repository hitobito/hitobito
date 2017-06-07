# encoding: utf-8

#  Copyright (c) 2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Person::Filter::Role < Person::Filter::Base

  def initialize(attr, args)
    super
    initialize_role_types
  end

  def apply(scope)
    scope.where(roles: { type: role_types.map(&:sti_name) })
  end

  def blank?
    args[:role_type_ids].blank?
  end

  def to_hash
    args.dup.tap do |hash|
      hash[:role_type_ids] = hash[:role_type_ids].join(ID_URL_SEPARATOR)
    end
  end

  private

  attr_reader :role_types

  def initialize_role_types
    @role_types = Role.types_by_ids(id_list(:role_type_ids))
    args[:role_type_ids] = @role_types.map(&:id)
  end

end
