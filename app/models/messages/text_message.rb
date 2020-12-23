# frozen_string_literal: true

#  Copyright (c) 2020, CVP Schweiz. This file is part of
#  hitobito_cvp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_cvp.

class Messages::TextMessage < Message

  validates :body, presence: true

  before_create :set_message_recipients

  def subject
    body[0..20] + '...'
  end

  private

  def target(person)
    person.phone_numbers.first.try? :number
  end
end
