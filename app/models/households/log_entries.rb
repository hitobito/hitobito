# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

class Households::LogEntries

  delegate :new_record?, :destroy?, :people,
    :new_people, :removed_people,
    :household_label, to: '@household'

  def initialize(household)
    @household = household
  end

  def create!
    return unless PaperTrail.enabled?
    raise 'PaperTrail.request.whodunnit must be set' if whodunnit.nil?

    log_events.each do |log_event|
      log_people.each do |person|
        changed_people(log_event).each do |changed_person|
          create_log_entry(person, changed_person, log_event)
        end
      end
    end
  end

  private

  def household_log_label
    people = log_people
    people -= new_people unless new_record?
    people -= removed_people if removed_people.present? && !destroy?

    people.map(&:full_name).join(', ')
  end

  def log_people
    people + removed_people
  end

  def create_log_entry(person, changed_person, log_event)
    PaperTrail::Version.create!(main: person,
                                item: person,
                                whodunnit: whodunnit,
                                event: log_event,
                                object: changed_person&.full_name,
                                object_changes: household_log_label)
  end

  def whodunnit
    PaperTrail.request.whodunnit
  end

  def log_events
    return [:household_created] if new_record?
    return [:household_destroyed] if destroy?

    events = []
    if new_people.present?
      events << :household_person_appended
    end
    if removed_people.present?
      events << :household_person_removed
    end
    events
  end

  def changed_people(log_event)
    case log_event
    when :household_person_appended
      new_people
    when :household_person_removed
      removed_people
    else
      [nil]
    end
  end

end
