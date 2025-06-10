# frozen_string_literal: true

#  Copyright (c) 2025-2025, Schweizer Wanderwege. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Bounce < ApplicationRecord
  class UnexpectedBlock < StandardError
    def initialize(mail, msg = nil)
      super(msg || "The checked mail (#{mail}) was blocked, but not expected to be.")
    end
  end

  BLOCK_THRESHOLD = 5

  scope :blocked, -> { where.not(blocked_at: nil) }
  scope :of_mailing_list, ->(id) {
    return self if id.blank?

    # && is "set union" in postgresql, so it is true if there is an overlap
    # between the param and the stored array.
    where("mailing_list_ids && '{:mailing_list_id}'", mailing_list_id: id)
  }

  before_validation :evaluate_blocking

  class << self
    def record(email, mailing_list_id: nil)
      bounce = find_or_initialize_by(email: email.strip.downcase)
      if mailing_list_id.present?
        bounce.mailing_list_ids ||= []

        unless bounce.mailing_list_ids.include?(mailing_list_id)
          bounce.mailing_list_ids << mailing_list_id
        end
      end
      bounce.increment!(:count)

      bounce.save
      bounce
    end

    # TODO: maybe extract this in a extra helper that controls blocking of mail-sending,
    #       independently of bounces, but that also controls the validity/futility.
    def blocked?(email)
      where(email: email).blocked.exists?
    end
  end

  def block!
    return blocked_at if blocked?

    now = DateTime.current
    update_attribute(:blocked_at, now)

    now
  end

  def blocked?
    blocked_at.present?
  end

  # find the first person there is to find
  def person
    Person.find_by(email: email) ||
      AdditionalEmail.find_by(email: email, contactable_type: "Person")&.contactable
  end

  def people
    Person.where(id: people_ids).all
  end

  # get a list of all people-ids associated with the email
  def people_ids
    Person.where(email: email).pluck(:id) |
      AdditionalEmail.where(email: email, contactable_type: "Person").pluck(:contactable_id)
  end

  def mailing_lists
    MailingList.where(id: mailing_list_ids).all
  end

  private

  def evaluate_blocking
    if blocked_at.nil? && count >= BLOCK_THRESHOLD
      self.blocked_at = DateTime.current
    end
  end
end
