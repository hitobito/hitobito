# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

require "spec_helper"

RSpec.describe ApplicationMailer, type: :mailer do
  before do
    SeedFu.quiet = true
    SeedFu.seed [Rails.root.join("db", "seeds")]
  end

  describe "subject" do
    it "unescapes html entities" do
      content = Fabricate(:custom_content,
        key: "test-content",
        placeholders_optional: "test-placeholder",
        subject: "Hello {test-placeholder}")
      expect(content.subject_with_values("test-placeholder" => "<a>World</a>"))
        .to eq("Hello &lt;a&gt;World&lt;/a&gt;")

      mailer = Class.new(described_class) do
        def test_mail = compose(["test@example.com"], "test-content")

        def placeholder_test_placeholder = "<a>World</a>"
      end

      expect(mailer.test_mail.subject).to eq("Hello <a>World</a>")
    end
  end

  context "translated sender" do
    around do |example|
      with_translations(
        de: {settings: {email: {sender: "de <de@%{mail_domain}>"}}},
        fr: {settings: {email: {sender: "fr <fr@%{mail_domain}>"}}}
      ) do
        example.call
      end
    end

    describe Event::ParticipationMailer do
      let(:person) { people(:top_leader) }
      let(:event) { Fabricate(:event) }

      it "has the sender per locale defined in the translation" do
        check_sender { Event::ParticipationMailer.cancel(event, person) }
      end
    end

    describe Address::ValidationChecksMailer do
      let(:invalid_people) { [people(:top_leader), people(:bottom_member)] }
      let(:invalid_people_names) { invalid_people.map(&:full_name).join(", ") }
      let(:recipient_email) { "validation_checks@example.com" }

      it "has the sender per locale defined in the translation" do
        check_sender { Address::ValidationChecksMailer.validation_checks(recipient_email, invalid_people_names) }
      end
    end

    describe Assignment::AssigneeNotificationMailer do
      let(:assignment) { assignments(:printing) }
      let(:assignee_email) { "assignee_notifications@example.com" }

      it "has the sender per locale defined in the translation" do
        check_sender { Assignment::AssigneeNotificationMailer.assignee_notification(assignee_email, assignment) }
      end
    end

    describe Event::RegisterMailer do
      let(:group) { event.groups.first }
      let(:event) { events(:top_event) }

      let(:person) { Fabricate(:person, email: "fooo@example.com", reset_password_token: "abc") }

      it "has the sender per locale defined in the translation" do
        check_sender { Event::RegisterMailer.register_login(person, group, event, "abcdef") }
      end
    end

    describe Groups::SelfRegistrationNotificationMailer do
      let(:role) { roles(:bottom_member) }
      let(:notification_email) { "self_registration_notification@example.com" }

      it "has the sender per locale defined in the translation" do
        check_sender { Groups::SelfRegistrationNotificationMailer.self_registration_notification(notification_email, role) }
      end
    end

    describe Person::AddRequestMailer do
      let(:person) do
        Fabricate(Group::BottomLayer::Member.name, group: groups(:bottom_layer_two)).person
      end
      let(:requester) do
        Fabricate(Group::BottomLayer::Leader.name, group: groups(:bottom_layer_one)).person
      end
      let(:group) { groups(:bottom_layer_one) }

      let(:request) do
        Person::AddRequest::Group.create!(
          person: person,
          requester: requester,
          body: group,
          role_type: Group::BottomLayer::Member.sti_name
        )
      end

      it "has the sender per locale defined in the translation" do
        check_sender { Person::AddRequestMailer.ask_person_to_add(request) }
      end
    end

    describe Person::InactivityBlockMailer do
      describe "#inactivity_block_warning" do
        let(:recipient) { people(:bottom_member) }

        it "has the sender per locale defined in the translation" do
          check_sender { described_class.inactivity_block_warning(recipient) }
        end
      end
    end

    describe Person::LoginMailer do
      let(:sender) { people(:top_leader) }
      let(:recipient) { people(:bottom_member) }

      it "has the sender per locale defined in the translation" do
        check_sender { Person::LoginMailer.login(recipient, sender, "abcdef") }
      end
    end

    describe Person::UserPasswordOverrideMailer do
      let(:sender) { people(:top_leader) }
      let(:recipient) { people(:bottom_member) }

      it "has the sender per locale defined in the translation" do
        check_sender { Person::UserPasswordOverrideMailer.send_mail(recipient, sender.full_name) }
      end
    end

    describe DeliveryReportMailer do
      let(:recipient_email) { "dude@hito42test.com" }
      let(:envelope_sender) { "liste@hitobito.example.com" }
      let(:mail_subject) { "Ausflugtips" }
      let(:total_recipients) { 42 }
      let(:delivered_at) { DateTime.now }
      let(:formatted_delivered_at) { I18n.l(delivered_at) }

      context "bulk mail success" do
        let(:failed_recipients) { nil }

        it "has the sender per locale defined in the translation" do
          check_sender { DeliveryReportMailer.bulk_mail(recipient_email, envelope_sender, mail_subject, total_recipients, delivered_at) }
        end
      end
    end

    describe InvoiceMailer do
      let(:invoice) { invoices(:invoice) }
      let(:sender) { people(:bottom_member) }

      it "has the sender per locale defined in the translation" do
        check_sender { InvoiceMailer.notification(invoice, sender) }
      end
    end
  end

  describe InvoiceMailer do
    let(:invoice) { invoices(:invoice) }
    let(:sender) { people(:bottom_member) }

    context "without translated sender" do
      it "has the sender defined in the settings if the locale changes" do
        check_sender(->(mail) { expect(mail[:from].value).to eq(Settings.email.sender) }) do
          InvoiceMailer.notification(invoice, sender)
        end
      end
    end

    context "With broken sender translation" do
      around do |example|
        with_translations(
          de: {settings: {email: {sender: "de broken email"}}},
          fr: {settings: {email: {sender: "fr broken email"}}}
        ) do
          example.call
        end
      end

      it "has the sender from the settings if the locale changes" do
        check_sender(->(message) { expect(message[:from].value).to eq(Settings.email.sender) }) do
          InvoiceMailer.notification(invoice, sender)
        end
      end
    end
  end
end

def check_sender(overwrite_checks = nil)
  [:fr, :de, :en].each do |locale|
    I18n.with_locale(locale) do
      locale = :de if locale == :en
      mail = yield
      if overwrite_checks
        overwrite_checks.call(mail)
      else
        expected_sender = "#{locale} <#{locale}@%{mail_domain}>"
        expect(I18n.t("settings.email.sender")).to eq expected_sender
        domain = Settings.email.list_domain
        expect(mail[:from].value).to eq("#{locale} <#{locale}@#{domain}>")
      end
    end
  end
end
