# frozen_string_literal: true

#  Copyright (c) 2020, CVP Schweiz. This file is part of
#  hitobito_cvp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_cvp.

class Message < ActiveRecord::Base
  belongs_to :recipients_source, polymorphic: true
  has_many :message_recipients

  attr_readonly :type

  class_attribute :default_recipient_status
  self.default_recipient_status = :delivered

  scope :list, -> { order(:updated_at) }

  ### INSTANCE METHODS

  private

  def set_message_recipients
    self.message_recipients.destroy_all
    self.message_recipients = recipients_source.people.map { |person| message_recipient(person) }
  end

  def message_recipient(person)
    MessageRecipient.new(
        message: self,
        person: person,
        state: self.class.default_recipient_status,
        target: target(person)
    )
  end

  def target(person)
    person.email
  end

  ### CLASS METHODS

  class << self
    def in_year(year)
      year = Time.zone.today.year if year.to_i <= 0
      start_at = Time.zone.parse "#{year}-01-01"
      finish_at = start_at + 1.year
      where(updated_at: [start_at...finish_at])
    end

    def user_types
      { text_message: Messages::TextMessage,
        letter: Messages::Letter
      }.with_indifferent_access
    end
  end
end
