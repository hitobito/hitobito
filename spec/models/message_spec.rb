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

#  Copyright (c) 2012-2021, CVP Schweiz. This file is part of
#  hitobito_cvp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Message do
  it "#to_s shows truncated subject with type" do
    subject.subject = "This is a very long text"
    subject.type = Message::Letter.sti_name
    expect(subject.to_s).to eq "Brief: This is a very lo..."
  end

  it "can create message without sender" do
    mailing_lists(:leaders).messages.create!(subject: "test", type: "Message")
  end

  context "#destroy" do
    subject { messages(:simple) }

    it "might be destroy when no dispatch exists" do
      expect(subject.destroy).to be_truthy
    end

    it "existing recipient prevents destruction" do
      subject.message_recipients.create!(person: people(:top_leader))
      expect(subject.reload.destroy).to eq false
    end
  end
end
