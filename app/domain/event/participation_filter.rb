# encoding: utf-8

#  Copyright (c) 2012-2014, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Event::ParticipationFilter

  PREDEFINED_FILTERS = %w(all teamers participants)
  SEARCH_COLUMNS = %w(people.first_name people.last_name people.nickname).freeze

  class_attribute :load_entries_includes
  self.load_entries_includes = [:roles, :event,
                                answers: [:question],
                                person: [:additional_emails, :phone_numbers,
                                         :primary_group]
                               ]

  attr_reader :params, :counts

  def initialize(event_id, user_id, params = {})
    @event_id = event_id
    @user_id = user_id
    @params = params
  end

  def list_entries
    records = params[:q].present? ? load_entries.where(search_condition) : load_entries
    @counts = populate_counts(records)
    apply_default_sort(apply_filter_scope(records))
  end

  def predefined_filters
    PREDEFINED_FILTERS
  end

  def event
    Event.find_by(id: @event_id)
  end

  def user
    Person.find_by(id: @user_id)
  end

  private

  def search_condition
    SearchStrategies::SqlConditionBuilder.new(params[:q], SEARCH_COLUMNS).search_conditions
  end

  def apply_default_sort(records)
    records = records.order_by_role(event) if Settings.people.default_sort == 'role'
    records.merge(Person.order_by_name)
  end

  def populate_counts(records)
    predefined_filters.each_with_object({}) do |name, memo|
      memo[name] = apply_filter_scope(records, name).count
    end
  end

  def load_entries
    event.active_participations_without_affiliate_types.
      includes(load_entries_includes).
      references(:people).
      uniq
  end

  def apply_filter_scope(records, kind = params[:filter])
    case kind
    when 'all'
      records
    when 'teamers'
      records.where.not('event_roles.type' => event.participant_types.collect(&:sti_name))
    when 'participants'
      records.where('event_roles.type' => event.participant_types.collect(&:sti_name))
    else
      if event.participation_role_labels.include?(kind)
        records.where('event_roles.label' => kind)
      else
        records
      end
    end
  end

end
