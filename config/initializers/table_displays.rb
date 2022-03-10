# frozen_string_literal: true

#  Copyright (c) 2022, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

Rails.application.config.to_prepare do
  public_person_attrs = Person::PUBLIC_ATTRS -
      %i(first_name last_name nickname zip_code town address picture primary_group_id) -
      Person::INTERNAL_ATTRS

  TableDisplay.register_permission(Person, :show, *public_person_attrs)
  TableDisplay.register_permission(Person,:update,:login_status)

  TableDisplay.register_permission(Event::Participation, :show,
      *(public_person_attrs.collect { |column| "person.#{column}" })
  )
end
