# frozen_string_literal: true

#  Copyright (c) 2023, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Person::BlockService
  def initialize(person, current_user: nil)
    @person = person
    @current_user = current_user
  end

  def block!
    @person.update_columns(blocked_at: Time.zone.now) &&
      log(:block_person)
  end

  def unblock!
    @person.update_columns(blocked_at: nil, inactivity_block_warning_sent_at: nil) &&
      log(:unblock_person)
  end

  def inactivity_warning!
    Person::InactivityBlockMailer.inactivity_block_warning(@person).deliver &&
      @person.update_columns(inactivity_block_warning_sent_at: Time.zone.now)
  end

  class << self
    def warn_after
      @warn_after ||= load_duration(:warn_after)
    end

    def block_after
      @block_after ||= load_duration(:block_after)
    end

    def warn_after_days
      warn_after&.in_days&.to_i
    end

    def block_after_days
      block_after&.in_days&.to_i
    end

    def inactivity_block_interval_placeholders
      {
        'warn-after-days' => warn_after_days.to_s,
        'block-after-days' => block_after_days.to_s,
      }
    end

    def warn?
      warn_after.present?
    end

    def block?
      block_after.present?
    end

    def block_scope
      return Person.none unless block?

      Person.where(blocked_at: nil)
            .where(Person.arel_table[:inactivity_block_warning_sent_at].lt(block_after&.ago))
    end

    def block_within_scope!
      return unless block?

      block_scope.find_each do |person|
        new(person).block!
      end
      true
    end

    def warn_scope
      return Person.none unless warn?

      Person.
        where(inactivity_block_warning_sent_at: nil, blocked_at: nil).
        where(Person.arel_table[:last_sign_in_at].lt(warn_after&.ago))
    end

    def warn_within_scope!
      return unless warn?

      warn_scope.find_each do |person|
        new(person).inactivity_warning!
      end
      true
    end

    private

    def load_duration(key)
      duration = Settings.people.inactivity_block[key].presence || return
      ActiveSupport::Duration.parse(duration.to_s)
    rescue ActiveSupport::Duration::ISO8601Parser::ParsingError, ArgumentError
      raise <<~MSG
        Settings.people.inactivity_block.#{key} must be a duration in ISO 8601 format, but is #{duration.inspect}".
        See https://en.wikipedia.org/wiki/ISO_8601#Durations
      MSG
    end
  end

  protected

  def log(event)
    PaperTrail::Version.create(main: @person, item: @person, whodunnit: @current_user, event: event)
  end
end
