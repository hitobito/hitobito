# == Schema Information
#
# Table name: messages
#
#  id                 :bigint           not null, primary key
#  failed_count       :integer          default(0)
#  heading            :boolean          default(FALSE)
#  invoice_attributes :text(65535)
#  recipient_count    :integer          default(0)
#  salutation         :string(255)      default("none"), not null
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

#  Copyright (c) 2012-2021, CVP Schweiz. This file is part of
#  hitobito_cvp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Message do

  it '#to_s shows truncated subject with type' do
    subject.subject = 'This is a very long text'
    subject.type = Message::Letter.sti_name
    expect(subject.to_s).to eq 'Brief: This is a very lo...'
  end

  it 'can create message without sender' do
    mailing_lists(:leaders).messages.create!(subject: 'test', type: 'Message')
  end

  context '#destroy' do
    subject { messages(:simple) }

    it 'might be destroy when no dispatch exists' do
      expect(subject.destroy).to be_truthy
    end

    it 'existing recipient prevents destruction' do
      subject.message_recipients.create!(person: people(:top_leader))
      expect(subject.reload.destroy).to eq false
    end
  end
end
