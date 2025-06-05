# frozen_string_literal: true

#  Copyright (c) 2012-2014, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Event::ParticipationFilter
  PREDEFINED_FILTERS = %w[all teamers participants]
  SEARCH_COLUMNS = [
    {
      participant_type: {
        "Person" => ["people.nickname", "people.first_name", "people.last_name"],
        "Event::Guest" => ["event_guests.nickname", "event_guests.first_name", "event_guests.last_name"]
      }
    }
  ].freeze

  class_attribute :load_entries_includes
  self.load_entries_includes = [:roles, :event,
    answers: [:question],
    person: [:additional_emails, :phone_numbers,
      :primary_group]]

  attr_reader :event, :user, :params, :counts

  def initialize(event, user, params = {})
    @event = event
    @user = user
    @params = params
  end

  def list_entries
    records = params[:q].present? ? load_entries.where(search_condition) : load_entries

    Event::Participation::PreloadParticipations.preload(records)

    @counts = populate_counts(records)
    apply_default_sort(apply_filter_scope(records))
  end

  def predefined_filters
    PREDEFINED_FILTERS
  end

  private

  def search_condition
    SearchStrategies::SqlConditionBuilder.new(params[:q], SEARCH_COLUMNS).search_conditions
  end

  def apply_default_sort(records)
    records = records.order_by_role(event) if Settings.people.default_sort == "role"

    records
      .select(polymorphic_order_by_name_statement)
      .order(polymorphic_order_by_name_statement)
      .select(Event::Participation.column_names)
  end

  def polymorphic_order_by_name_statement
    person_order = Person.order_by_name_statement
    guest_order = Event::Guest.order_by_name_statement

    Arel.sql(
      <<~SQL.squish
        CASE event_participations.participant_type
          WHEN 'Person' THEN #{person_order}
          WHEN 'Event::Guest' THEN #{guest_order}
          ELSE ''
        END
      SQL
    )
  end

  def populate_counts(records)
    predefined_filters.each_with_object({}) do |name, memo|
      memo[name] = apply_filter_scope(records, name).count
    end
  end

  def load_entries
    event.active_participations_without_affiliate_types
      .distinct
      .with_person_participants
      .with_guest_participants
  end

  def apply_filter_scope(records, kind = params[:filter])
    case kind
    when "all"
      records
    when "teamers"
      records.where.not("event_roles.type" => event.participant_types.collect(&:sti_name))
    when "participants"
      records.where("event_roles.type" => event.participant_types.collect(&:sti_name))
    else
      if event.participation_role_labels.include?(kind)
        records.where("event_roles.label" => kind)
      else
        records
      end
    end
  end
end
