# encoding: utf-8

#  Copyright (c) 2012-2014, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Event::ParticipationFilter

  PREDEFINED_FILTERS = %w(all teamers participants)

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
    PREDEFINED_FILTERS.each_with_object({}) do |name, memo|
      memo[name] = apply_filter_scope(records, name).count
    end
  end

  def load_entries
    event.participations.
      active.
      joins(:roles).
      where(exclude_affiliate_types).
      includes(:roles, :event, :answers, person: [:additional_emails, :phone_numbers]).
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

  def exclude_affiliate_types
    affiliate_types = event.role_types.reject(&:kind).collect(&:sti_name)
    if affiliate_types.present?
      ['event_roles.type NOT IN (?)', affiliate_types]
    end
  end

end
