# encoding: utf-8

#  Copyright (c) 2012-2014, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Event::ParticipationFilter

  attr_reader :event, :user, :params, :counts

  def initialize(event, user, params = {})
    @event = event
    @user = user
    @params = params
  end

  def list_entries
    records = load_entries
    @counts = populate_counts(records)
    apply_default_sort(apply_filter_scope(records))
  end

  private

  def apply_default_sort(records)
    records = records.order_by_role(event.class) if Settings.people.default_sort == 'role'
    records.merge(Person.order_by_name)
  end

  def populate_counts(records)
    FilterNavigation::Event::Participations::PREDEFINED_FILTERS.each_with_object({}) do |name, memo|
      memo[name] = apply_filter_scope(records, name).count
    end
  end

  def load_entries
    event.participations.
      where(event_participations: { active: true }).
      joins(:roles).
      includes(:roles, :event, :answers, person: [:additional_emails, :phone_numbers]).
      participating(event).
      uniq
  end

  def apply_filter_scope(records, kind = params[:filter])
    # default event filters
    valid_scopes = FilterNavigation::Event::Participations::PREDEFINED_FILTERS
    scope = valid_scopes.detect { |k| k.to_s == kind }
    if scope
      # do not use params[:filter] in send to satisfy brakeman
      records = records.send(scope, event) unless scope.to_s == 'all'
      # event specific filters (filter by role label)
    elsif event.participation_role_labels.include?(kind)
      records = records.with_role_label(kind)
    end
    records
  end

end
