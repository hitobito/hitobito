# == Schema Information
#
# Table name: messages
#
#  id              :bigint           not null, primary key
#  failed_count    :integer          default(0)
#  recipient_count :integer          default(0)
#  sent_at         :datetime
#  state           :string(255)      default("draft")
#  subject         :string(1024)     not null
#  success_count   :integer          default(0)
#  type            :string(255)      not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  mailing_list_id :bigint
#  sender_id       :bigint
#
# Indexes
#
#  index_messages_on_mailing_list_id  (mailing_list_id)
#  index_messages_on_sender_id        (sender_id)
#

#  Copyright (c) 2021, CVP Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Message::TextMessage < Message
  self.icon = :sms

  validates :text, length: {minimum: 1, maximum: 160}

  def subject
    text && text[0..20]
  end
end
