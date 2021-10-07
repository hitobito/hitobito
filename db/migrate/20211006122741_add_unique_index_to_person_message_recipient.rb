# frozen_string_literal: true

#  Copyright (c) 2021, Die Mitte. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class AddUniqueIndexToPersonMessageRecipient < ActiveRecord::Migration[6.0]

  def change
    add_index(:message_recipients, [:person_id, :message_id, :address],
              unique: true,
              name: :index_message_recipients_on_person_message_address)
    add_index(:message_recipients, [:person_id, :message_id, :phone_number],
              unique: true,
              name: :index_message_recipients_on_person_message_phone_number)
    add_index(:message_recipients,
              [:person_id, :message_id, :email],
              unique: true,
              name: :index_message_recipients_on_person_message_email)
  end
end
