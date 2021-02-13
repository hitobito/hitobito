# == Schema Information
#
# Table name: mail_logs
#
#  id                :integer          not null, primary key
#  mail_from         :string(255)
#  mail_hash         :string(255)
#  mailing_list_name :string(255)
#  status            :integer          default("retreived")
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  message_id        :bigint
#
# Indexes
#
#  index_mail_logs_on_mail_hash   (mail_hash)
#  index_mail_logs_on_message_id  (message_id)
#
#  Copyright (c) 2012-2021, CVP Schweiz. This file is part of
#  hitobito_cvp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe MailLog do
  let(:mail) { Mail.new(File.read(Rails.root.join("spec", "fixtures", "email", "simple.eml"))) }
  let(:mail_log) do
    log = MailLog.build(mail)
    log.save!
    log
  end

  context "mail=" do
    it "assigns bulk mail message" do
      log = MailLog.new
      log.mail = mail

      expect(log.message.subject).to eq(mail.subject)
    end
  end

  context "#update" do
    context "changes message state" do
      {retreived: :pending,
       bulk_delivering: :processing,
       completed: :finished,
       unkown_recipient: :failed,
       sender_rejected: :failed,}.each_pair do |log_status, expected_message_state|
        it "to #{expected_message_state} if mail_log status is #{log_status}" do
          mail_log.update!(status: log_status)

          expect(mail_log.message.state).to eq(expected_message_state.to_s)
        end
      end
    end
  end
end
