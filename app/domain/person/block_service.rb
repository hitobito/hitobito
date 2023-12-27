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
    @person.update!(blocked_at: Time.zone.now) && log(:block_person)
  end

  def unblock!
    @person.update!(blocked_at: nil, inactivity_block_warning_sent_at: nil) && log(:unblock_person)
  end

  def inactivity_warning!
    Person::InactivityBlockMailer.inactivity_block_warning(@person).deliver &&
      @person.update!(inactivity_block_warning_sent_at: Time.zone.now)
  end

  class << self
    def warn_after
      Settings.people&.inactivity_block&.warn_after&.to_i&.seconds
    end

    def block_after
      Settings.people&.inactivity_block&.block_after&.to_i&.seconds
    end

    def warn_block_period
      return unless warn_after && block_after

      block_after - warn_after
    end

    def inactivity_block_interval_placeholders
      {
        'warn-after-days' => warn_after,
        'block-after-days' => block_after,
        'warn-block-period-days' => warn_block_period,
      }.transform_values { _1&.in_days&.to_i&.to_s }
    end


    def warn?
      warn_after.present? && warn_after.positive?
    end

    def block?
      block_after.present? && block_after.positive?
    end

    def block_scope(block_after = self.block_after)
      return unless block?

      Person.where.not(last_sign_in_at: nil)
            .where(blocked_at: nil)
            .where(Person.arel_table[:last_sign_in_at].lt(block_after&.ago))
    end

    def block_within_scope!
      return unless block?

      block_scope.find_each do |person|
        new(person).block!
      end
    end

    def warn_scope(warn_after = self.warn_after)
      return unless warn?

      Person.where.not(last_sign_in_at: nil)
            .where(Person.arel_table[:last_sign_in_at].lt(warn_after&.ago))
            .where(inactivity_block_warning_sent_at: nil, blocked_at: nil)
    end

    def warn_within_scope!
      return unless warn?

      warn_scope.find_each do |person|
        new(person).inactivity_warning!
      end
    end
  end

  protected

  def log(event)
    PaperTrail::Version.create(main: @person, item: @person, whodunnit: @current_user, event: event)
  end
end
