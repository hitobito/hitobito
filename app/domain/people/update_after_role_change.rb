# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of hitobito and licensed under the
#  Affero General Public License version 3 or later. See the COPYING file at the top-level directory
#  or at https://github.com/hitobito/hitobito.

class People::UpdateAfterRoleChange
  def initialize(person)
    @person = person
  end

  def set_contact_data_visible
    person.update_column(:contact_data_visible, contact_data?) if person.contact_data_visible != contact_data?
  end

  def set_first_primary_group
    person.update_column(:primary_group_id, newest_group_id) if no_role_in_primary_group?
  end

  private

  attr_reader :person

  def newest_group_id
    roles.max_by(&:updated_at)&.group_id
  end

  def no_role_in_primary_group?
    roles.where(group_id: person.primary_group_id).none?
  end

  def contact_data?
    roles.flat_map(&:permissions).include?(:contact_data)
  end

  def roles
    person.roles.active
  end
end
