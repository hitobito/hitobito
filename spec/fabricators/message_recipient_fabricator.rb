# frozen_string_literal: true

#  Copyright (c) 2024-2024, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# == Schema Information
#
# Table name: message_recipients
#
#  id           :bigint           not null, primary key
#  address      :text(65535)
#  email        :string(255)
#  error        :text(65535)
#  failed_at    :datetime
#  phone_number :string(255)
#  salutation   :string(255)      default("")
#  state        :string(255)
#  created_at   :datetime
#  invoice_id   :bigint
#  message_id   :bigint           not null
#  person_id    :bigint
#
# Indexes
#
#  index_message_recipients_on_invoice_id                   (invoice_id)
#  index_message_recipients_on_message_id                   (message_id)
#  index_message_recipients_on_person_id                    (person_id)
#  index_message_recipients_on_person_message_address       (person_id,message_id,address) UNIQUE
#  index_message_recipients_on_person_message_email         (person_id,message_id,email) UNIQUE
#  index_message_recipients_on_person_message_phone_number  (person_id,message_id,phone_number) UNIQUE
#


Fabricator(:message_recipient) do
  message { Fabricate(:letter) }
  person { Fabricate(:person) }

  state { :pending }

  address { Faker::Address.street_address }
  email do
    first = Faker::Name.first_name
    last = Faker::Name.last_name
    "#{first}.#{last}#{sequence}@hitobito.example.com"
  end
  phone_number { Fabricate(:phone_number) }
end
