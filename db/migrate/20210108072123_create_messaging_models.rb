# frozen_string_literal: true
#
#  Copyright (c) 2012-2021, CVP Schweiz. This file is part of
#  hitobito_cvp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#
#  https://github.com/hitobito/hitobito

class CreateMessagingModels < ActiveRecord::Migration[6.0]
  def change
    create_table :messages do |t|
      t.belongs_to :mailing_list
      t.belongs_to :sender

      t.string :type, null: false
      t.string :subject, null: false, limit: 1024

      t.string :state, default: :draft

      t.integer :recipient_count, default: 0
      t.integer :success_count, default: 0
      t.integer :failed_count, default: 0

      t.timestamp :sent_at

      t.timestamps
    end

    create_table :message_recipients do |t|
      t.belongs_to :message, null: false
      t.belongs_to :person, null: false
      t.string :phone_number
      t.string :email
      t.string :address
      t.timestamp :created_at
      t.timestamp :failed_at
      t.text :error
    end
  end
end
