# encoding: utf-8

#  Copyright (c) 2012-2014, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Event::Participatable

  def refresh_participant_counts!
    update_column(:teamer_count, count_teamers)
    update_column(:participant_count, count_participants)
    update_column(:applicant_count, count_applicants)
  end

  def participations_for(*role_types)
    participations.active.
                   joins(:roles).
                   where(event_roles: { type: role_types.map(&:sti_name) }).
                   includes(:person).
                   references(:person).
                   order_by_role(self.class).
                   merge(Person.order_by_name).
                   uniq
  end

  def active_participations_without_affiliate_types
    affiliate_types = role_types.reject(&:kind).collect(&:sti_name)
    exclude_affiliate_types = affiliate_types.present? &&
      ['event_roles.type NOT IN (?)', affiliate_types]

    participations.active.
                   joins(:roles).
                   where(exclude_affiliate_types)
  end

  # gets a list of all user defined participation role labels for this event
  def participation_role_labels
    @participation_role_labels ||=
      Event::Role.joins(:participation).
                  where('event_participations.event_id = ?', id).
                  where('event_roles.label <> ""').
                  uniq.order(:label).
                  pluck(:label)
  end

  def participant_types
    self.class.participant_types
  end

  private

  # Sum all members of the leading team (non-participants)
  def count_teamers
    active_participations_without_affiliate_types.
                   where.not(event_roles: { type: participant_types.collect(&:sti_name) }).
                   distinct.
                   count
  end

  # Sum all assigned participations (no leaders/teamers)
  def count_participants
    participations.active.
                   joins(:roles).
                   where(event_roles: { type: participant_types.collect(&:sti_name) }).
                   distinct.
                   count
  end

  # Sum assigned participations (all prios, no leaders/teamers) and unassigned with prio 1
  def count_applicants
    participations.
      joins('LEFT JOIN event_roles ON event_participations.id = event_roles.participation_id').
      where('event_roles.participation_id IS NULL OR event_roles.type IN (?)',
            participant_types.collect(&:sti_name)).
      distinct.
      count
  end
end
