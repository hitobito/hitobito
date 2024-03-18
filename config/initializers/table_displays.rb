# frozen_string_literal: true

#  Copyright (c) 2022-2024, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

Rails.application.config.to_prepare do
  show_details_person_attrs = %i(gender birthday language)
  public_person_attrs = (
    Person::PUBLIC_ATTRS -
    %i(first_name last_name nickname zip_code town address picture) -
    show_details_person_attrs -
    Person::INTERNAL_ATTRS
  ) & Person.used_attributes

  TableDisplay.register_column(Person,
                               TableDisplays::PublicColumn,
                               public_person_attrs)
  TableDisplay.register_column(Person,
                               TableDisplays::ShowDetailsColumn,
                               show_details_person_attrs)
  TableDisplay.register_column(Person,
                               TableDisplays::People::LayerGroupLabelColumn,
                               :layer_group_label)
  TableDisplay.register_column(Person,
                               TableDisplays::People::LoginStatusColumn,
                               :login_status)

  TableDisplay.register_column(Event::Participation,
                               TableDisplays::PublicColumn,
                               public_person_attrs.map { |column| "person.#{column}" })
  TableDisplay.register_column(Event::Participation,
                               TableDisplays::Event::Participations::ShowDetailsOrEventLeaderColumn,
                               show_details_person_attrs.map { |column| "person.#{column}" })
  TableDisplay.register_column(Event::Participation,
                               TableDisplays::People::LayerGroupLabelColumn,
                               "person.layer_group_label")
  TableDisplay.register_multi_column(Event::Participation,
                                     TableDisplays::Event::Participations::QuestionColumn)
  TableDisplay.register_column(Event::Participation,
                               TableDisplays::Event::Participations::ShowDetailsOrEventLeaderColumn,
                               :additional_information)
end
