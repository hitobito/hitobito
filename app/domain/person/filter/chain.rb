# frozen_string_literal: true

#  Copyright (c) 2017 - 2018, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Person::Filter::Chain < Filter::Chain
  self.types = [ # rubocop:disable Style/MutableConstant these are meant to be extended in wagons
    Person::Filter::Role,
    Person::Filter::Qualification,
    Person::Filter::Attributes,
    Person::Filter::Language,
    Person::Filter::Tag,
    Person::Filter::TagAbsence
  ]

  # Person-specific methods
  def include_ended_roles?
    filters.any?(&:include_ended_roles?)
  end

  def roles_join
    first_custom_roles_join || {roles: :group}
  end

  private

  def first_custom_roles_join
    filters.collect(&:roles_join).compact.first
  end
end
