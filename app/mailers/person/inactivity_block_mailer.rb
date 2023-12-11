# encoding: utf-8
# frozen_string_literal: true

#  Copyright (c) 2022, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Person::InactivityBlockMailer < ApplicationMailer

  CONTENT_INACTIVITY_BLOCK_WARNING = 'content_inactivity_block_warning'.freeze

  # delegate :body, :person, :requester, to: :password_override

  def inactivity_block_warning(recipient)
    @recipient = recipient

    compose(recipient, CONTENT_INACTIVITY_BLOCK_WARNING)
  end

  private

  def placeholder_recipient_name
    @recipient.greeting_name
  end


  def placeholder_warn_after
    Person::BlockService.warn? && distance_of_time_in_words(Person::BlockService.warn_after)
  end

  def placeholder_block_after
    Person::BlockService.block? && distance_of_time_in_words(Person::BlockService.block_after)
  end
end
