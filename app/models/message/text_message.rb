# frozen_string_literal: true

# Copyright (c) 2021, CVP Schweiz. This file is part of
# hitobito and licensed under the Affero General Public License version 3
# or later. See the COPYING file at the top-level directory or at
# https://github.com/hitobito/hitobito.

# == Schema Information
#
# Table name: messages
#
#  id                    :bigint           not null, primary key
#  date_location_text    :string
#  donation_confirmation :boolean          default(FALSE), not null
#  failed_count          :integer          default(0)
#  invoice_attributes    :text
#  pp_post               :string
#  raw_source            :text
#  recipient_count       :integer          default(0)
#  salutation            :string
#  send_to_households    :boolean          default(FALSE), not null
#  sent_at               :datetime
#  shipping_method       :string           default("own")
#  state                 :string           default("draft")
#  subject               :string(998)
#  success_count         :integer          default(0)
#  text                  :text
#  type                  :string           not null
#  uid                   :string
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

class Message::TextMessage < Message
  self.icon = :sms

  validates :text, length: {minimum: 1, maximum: 603}

  def subject
    text && text[0..20]
  end

  def update_message_status!
    failed_count = message_recipients.where(state: "failed").count
    success_count = message_recipients.where(state: "sent").count
    state = (success_count.eql?(0) && failed_count.positive?) ? "failed" : "finished"
    update!(success_count: success_count, failed_count: failed_count, state: state)
  end
end
