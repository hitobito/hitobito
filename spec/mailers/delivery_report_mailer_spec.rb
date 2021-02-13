# encoding: utf-8

#  Copyright (c) 2012-2018, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe DeliveryReportMailer do

  let(:recipient_email) { "dude@hito42test.com" }
  let(:envelope_sender) { "liste@hitobito.example.com" }
  let(:sent_message) do
    mail = Mail.new
    mail.subject = "Ausflugtips"
    mail.to = "me@mymail.org, liste@hitobito.example.com"
    mail
  end
  let(:total_recipients) { 42 }
  let(:delivered_at) { DateTime.now }
  let(:formatted_delivered_at) { I18n.l(delivered_at) }

  context "bulk mail success" do

    let(:failed_recipients) { nil }
    let(:delivery_report) { DeliveryReportMailer.bulk_mail(recipient_email, envelope_sender, sent_message, total_recipients, delivered_at) }

    subject { delivery_report }

    its(:to)       { should == [recipient_email] }
    its(:from)     { should == ["noreply@localhost"] }
    its(:subject)  { should == "Sendebericht Mail an liste@hitobito.example.com" }
    its(:body)     { should =~ /Deine Mail an liste@hitobito.example.com wurde verschickt:/}
    its(:body)     { should =~ /Zeit: #{formatted_delivered_at}/}
    its(:body)     { should =~ /Betreff: Ausflugtips/}
    its(:body)     { should =~ /Empfänger: 42/}

  end

  context "bulk mail with failed recipients" do

    let(:failed_recipient_one) { ["dude@gugunidgit.ch", "450 4.1.2 dude@gugunidgit.ch: Recipient address rejected: Domain not found"]}
    let(:failed_recipient_two) { ["dude2@gugunidgit.ch", "450 4.1.2 dude2@gugunidgit.ch: Recipient address rejected: Domain not found"]}
    let(:failed_recipients) { [failed_recipient_one, failed_recipient_two] }
    let(:delivery_report) { DeliveryReportMailer.bulk_mail(recipient_email, envelope_sender, sent_message, total_recipients, delivered_at, failed_recipients) }

    subject { delivery_report }

    its(:to)       { should == [recipient_email] }
    its(:from)     { should == ["noreply@localhost"] }
    its(:subject)  { should == "Sendebericht Mail an liste@hitobito.example.com" }
    its(:body)     { should =~ /Deine Mail an liste@hitobito.example.com wurde verschickt:/}
    its(:body)     { should =~ /Zeit: #{formatted_delivered_at}/}
    its(:body)     { should =~ /Betreff: Ausflugtips/}
    its(:body)     { should =~ /Empfänger: 40\/42/ }

  end

end
