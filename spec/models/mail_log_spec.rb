require "spec_helper"

describe MailLog do
  let(:mail) { Mail.new(Rails.root.join("spec", "fixtures", "email", "simple.eml").read) }
  let(:mail_log) do
    log = MailLog.build(mail)
    log.save!
    log
  end

  describe "normalization" do
    it "downcases mail_from" do
      mail_log.mail_from = "TesTer@gMaiL.com"
      expect(mail_log.mail_from).to eq "tester@gmail.com"
    end
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
