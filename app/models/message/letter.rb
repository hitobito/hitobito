# frozen_string_literal: true

#  Copyright (c) 2012-2021, CVP Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.
class Message::Letter < Message
  include Shippable

  has_rich_text :body
  self.icon = :"envelope-open-text"

  validates :subject, presence: true

  validates :body, presence: true

  duplicatable_attrs << "body" << "salutation" << "pp_post" << "shipping_method"

  def recipients
    @recipients ||= mailing_list.people(Person.with_address)
  end
end
