# == Schema Information
#
# Table name: mail_logs
#
#  id                :integer          not null, primary key
#  mail_from         :string
#  mail_hash         :string
#  mailing_list_name :string
#  status            :integer          default("retrieved")
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  message_id        :bigint
#
# Indexes
#
#  index_mail_logs_on_mail_hash   (mail_hash)
#  index_mail_logs_on_message_id  (message_id)
#

require "spec_helper"

describe MailLog do
  let(:mail) { Mail.new(Rails.root.join("spec", "fixtures", "email", "simple.eml").read) }
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
      {retrieved: :pending,
       bulk_delivering: :processing,
       completed: :finished,
       unknown_recipient: :failed,
       bounce_rejected: :failed,
       sender_rejected: :failed}.each_pair do |log_status, expected_message_state|
        it "to #{expected_message_state} if mail_log status is #{log_status}" do
          mail_log.update!(status: log_status)

          expect(mail_log.message.state).to eq(expected_message_state.to_s)
        end
      end
    end
  end
end
