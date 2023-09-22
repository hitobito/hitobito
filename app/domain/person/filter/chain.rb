# frozen_string_literal: true

#  Copyright (c) 2017 - 2018, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Person::Filter::Chain < Filter::Chain

  TYPES = [ # rubocop:disable Style/MutableConstant these are meant to be extended in wagons
    Person::Filter::Role,
    Person::Filter::Qualification,
    Person::Filter::Attributes,
    Person::Filter::Tag,
    Person::Filter::TagAbsence
  ]

  def roles_join
    first_custom_roles_join || { roles: :group }
  end

  protected

  def first_custom_roles_join
    filters.collect(&:roles_join).compact.first
  end

  def filter_type_key(attr)
    # TODO: map filter types for regular person attrs
    attr.to_s
  end

end
