# frozen_string_literal: true

#  Copyright (c) 2022-2026, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

Rails.application.config.to_prepare do
  always_shown = TableDisplays::People::ALWAYS_SHOWN_ATTRS
  ignored = [:primary_group_id]
  show_details_columns = [:gender, :birthday, :language]

  public_columns = (Person::PUBLIC_ATTRS - always_shown - ignored - show_details_columns - Person::INTERNAL_ATTRS) &
    Person.used_attributes
  for_participant = ->(columns) { columns.map { |column| "participant.#{column}" } }

  TableDisplay.register_column(Person, TableDisplays::PublicColumn, public_columns)
  TableDisplay.register_column(Person, TableDisplays::ShowDetailsColumn, show_details_columns)
  TableDisplay.register_column(Person, TableDisplays::People::PrimaryGroupColumn, :primary_group_id)
  TableDisplay.register_column(Person, TableDisplays::People::LayerGroupLabelColumn, :layer_group_label)
  TableDisplay.register_column(Person, TableDisplays::People::LoginStatusColumn, :login_status)

  TableDisplay.register_column(Event::Participation, TableDisplays::PolymorphicPublicColumn, for_participant.call(public_columns))
  TableDisplay.register_column(Event::Participation, TableDisplays::Event::Participations::ShowDetailsOrEventLeaderColumn, for_participant.call(show_details_columns))
  TableDisplay.register_column(Event::Participation, TableDisplays::People::PolymorphicLayerGroupLabelColumn, "participant.layer_group_label")
  TableDisplay.register_multi_column(Event::Participation, TableDisplays::Event::Participations::QuestionColumn)
  TableDisplay.register_column(Event::Participation, TableDisplays::ShowDetailsColumn, :"additional_information")
end
