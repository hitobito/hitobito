#  Copyright (c) 2022, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module TableDisplays
  class PolymorphicPublicColumn < PolymorphicColumn
    def required_permission(_attr)
      :show
    end

    def required_model_attrs(attr)
      [
        resolve_database_column(attr),
        # The can(:show) check requires the contact_data_visible column to be fetched from the db
        # for participants that are not people, but guests, this will be NULL
        "people.contact_data_visible"
      ].compact_blank
    end

    def render(attr)
      super do |target, target_attr|
        template.format_attr(target, target_attr) if target.respond_to?(target_attr)
      end
    end

    def sort_by(attr)
      relation, column = attr.to_s.split('.')

      # TODO do not hardcode the participant person / guest association here
      if ::Event::Guest.column_names.include?(column)
        {
          order: "CASE event_participations.participant_type WHEN 'Person' THEN people.#{column} WHEN 'Event::Guest' THEN event_guests.#{column} ELSE NULL END AS #{relation}_#{column}_order_statement",
          order_alias: "#{relation}_#{column}_order_statement"
        }
      else
        {
          order: "CASE event_participations.participant_type WHEN 'Person' THEN people.#{column} ELSE NULL END AS #{relation}_#{column}_order_statement",
          order_alias: "#{relation}_#{column}_order_statement"
        }
      end
    end
  end
end
