# == Schema Information
#
# Table name: messages
#
#  id                 :bigint           not null, primary key
#  failed_count       :integer          default(0)
#  heading            :boolean          default(FALSE)
#  invoice_attributes :text(65535)
#  recipient_count    :integer          default(0)
#  salutation         :string(255)
#  sent_at            :datetime
#  state              :string(255)      default("draft")
#  subject            :string(256)
#  success_count      :integer          default(0)
#  text               :text(65535)
#  type               :string(255)      not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  invoice_list_id    :bigint
#  mailing_list_id    :bigint
#  sender_id          :bigint
#
# Indexes
#
#  index_messages_on_invoice_list_id  (invoice_list_id)
#  index_messages_on_mailing_list_id  (mailing_list_id)
#  index_messages_on_sender_id        (sender_id)
#

#  Copyright (c) 2021, CVP Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Message::TextMessage < Message
  self.icon = :sms

  validates :text, length: { minimum: 1, maximum: 160 }

  def subject
    text && text[0..20]
  end

  def valid_recipient_count
    @valid_recipient_count ||= mailing_list.people_count(Person.with_mobile)
  end

  def update_message_status!
    failed_count = message_recipients.where(state: 'failed').count
    success_count = message_recipients.where(state: 'sent').count
    state = success_count.eql?(0) && failed_count.positive? ? 'failed' : 'finished'
    update!(success_count: success_count, failed_count: failed_count, state: state)
  end

end
