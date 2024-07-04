# frozen_string_literal: true

#  Copyright (c) 2022, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# == Schema Information
#
# Table name: messages
#
#  id                    :bigint           not null, primary key
#  date_location_text    :string(255)
#  donation_confirmation :boolean          default(FALSE), not null
#  failed_count          :integer          default(0)
#  invoice_attributes    :text(65535)
#  pp_post               :string(255)
#  raw_source            :text(16777215)
#  recipient_count       :integer          default(0)
#  salutation            :string(255)
#  send_to_households    :boolean          default(FALSE), not null
#  sent_at               :datetime
#  shipping_method       :string(255)      default("own")
#  state                 :string(255)      default("draft")
#  subject               :string(998)
#  success_count         :integer          default(0)
#  text                  :text(65535)
#  type                  :string(255)      not null
#  uid                   :string(255)
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  bounce_parent_id      :integer
#  invoice_list_id       :bigint
#  mailing_list_id       :bigint
#  sender_id             :bigint
#
# Indexes
#
#  index_messages_on_invoice_list_id  (invoice_list_id)
#  index_messages_on_mailing_list_id  (mailing_list_id)
#  index_messages_on_sender_id        (sender_id)
#

class Message::BulkMailBounce < Message
  belongs_to :bounce_parent, class_name: "Message::BulkMail"
end
