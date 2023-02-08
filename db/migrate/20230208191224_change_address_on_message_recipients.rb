# frozen_string_literal: true

#  Copyright (c) 2023-2023, Die Mitte Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class ChangeAddressOnMessageRecipients < ActiveRecord::Migration[6.1]
  def up
    remove_index  :message_recipients, name: "index_message_recipients_on_person_message_address"

    change_column :message_recipients, :address, :text

    add_index     :message_recipients, ["person_id", "message_id", "address"],
                                       name: "index_message_recipients_on_person_message_address",
                                       length: { address: 255 }, # assume size of utf8-varchar
                                       unique: true
  end

  def down
    remove_index  :message_recipients, name: "index_message_recipients_on_person_message_address"

    change_column :message_recipients, :address, :string

    add_index     :message_recipients, ["person_id", "message_id", "address"],
                                       name: "index_message_recipients_on_person_message_address",
                                       unique: true
  end
end

