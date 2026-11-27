# frozen_string_literal: true

#  Copyright (c) 2026, Berner Fachhochschule. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Event::ApiRegistration::Applicant do
  let(:event) { events(:top_event) }
  let(:values) { {first_name: "Anna", last_name: "Muster", email: "anna@example.com"} }
  let(:privacy_policy_accepted) { false }
  let(:errors) { ActiveModel::Errors.new(Person.new) }

  subject(:applicant) { described_class.new(event, values, privacy_policy_accepted:) }

  def validate
    applicant.validate(errors)
    errors
  end

  def attach_privacy_policy
    file = Rails.root.join("spec", "fixtures", "files", "images", "logo.png")
    policy = ActiveStorage::Blob.create_and_upload!(io: File.open(file, "rb"),
      filename: "logo.png", content_type: "image/png").signed_id
    groups(:top_layer).update!(privacy_policy: policy)
  end

  describe ".person_attributes" do
    it "are the contact attributes of events, with a single phone number" do
      expect(described_class.person_attributes).to include(:first_name, :email, :phone_number)
      expect(described_class.person_attributes).not_to include(:phone_numbers)
    end

    it "include attributes added by wagons" do
      allow(Event).to receive(:possible_contact_attrs)
        .and_return(Event.possible_contact_attrs + [:additional_information])
      values[:additional_information] = "Firma AG"

      expect(applicant.values).to include(additional_information: "Firma AG")
      expect(applicant.person.additional_information).to eq "Firma AG"
    end
  end

  describe "#validate" do
    it "accepts first name, last name and email" do
      expect(validate).to be_empty
    end

    it "requires the mandatory contact attributes" do
      values.replace(nickname: "Anni")
      expect(validate.details.transform_values { |d| d.pluck(:error) })
        .to include(first_name: [:blank], last_name: [:blank], email: [:blank])
    end

    it "requires the contact attributes required by the event" do
      event.update!(required_contact_attrs: %w[town phone_numbers])
      expect(validate.of_kind?(:town, :blank)).to be true
      expect(validate.of_kind?(:phone_number, :blank)).to be true
    end

    it "rejects contact attributes hidden by the event" do
      event.update!(hidden_contact_attrs: %w[nickname])
      values[:nickname] = "Anni"
      expect(validate.of_kind?(:nickname, :not_allowed)).to be true
    end

    it "rejects invalid email addresses once" do
      values[:email] = "anna-at-example"
      expect(validate.details[:email]).to eq [{error: :invalid}]
    end

    it "rejects email addresses failing hitobito's email check" do
      allow(Truemail).to receive(:valid?).and_return(false)
      values[:email] = "anna@unknown-domain.ch"
      expect(validate.details[:email]).to eq [{error: :invalid}]
    end

    it "does not reveal that a person with the email exists" do
      values[:email] = people(:top_leader).email.upcase
      expect(validate).to be_empty
    end

    it "reports invalid person attributes" do
      values[:gender] = "x"
      expect(validate).to include(:gender)
    end

    it "reports invalid phone numbers on phone_number" do
      values[:phone_number] = "not a number"
      expect(validate).to include(:phone_number)
    end

    context "with privacy policy" do
      before { attach_privacy_policy }

      it "requires its acceptance" do
        expect(validate.of_kind?(:privacy_policy_accepted, :accepted)).to be true
      end

      context "accepted" do
        let(:privacy_policy_accepted) { true }

        it "is valid" do
          expect(validate).to be_empty
        end
      end

      context "of an existing person who has accepted before" do
        before do
          people(:top_leader).update!(privacy_policy_accepted: true)
          values[:email] = people(:top_leader).email
        end

        it "requires its acceptance again, not to reveal the person" do
          expect(validate.of_kind?(:privacy_policy_accepted, :accepted)).to be true
        end
      end
    end
  end

  describe "#person" do
    it "finds an existing person by email ignoring case" do
      values[:email] = people(:top_leader).email.upcase
      expect(applicant.person).to eq people(:top_leader)
      expect(applicant).to be_existing_person
    end

    it "builds a new person without password, roles or privacy acceptance" do
      person = applicant.person
      expect(applicant).not_to be_existing_person
      expect(person).to be_new_record
      expect(person.attributes.symbolize_keys).to include(first_name: "Anna", last_name: "Muster",
        email: "anna@example.com", encrypted_password: nil)
      expect(person.roles).to be_empty
      expect(person.privacy_policy_accepted_at).to be_nil
    end

    it "uses the submitted language" do
      values[:language] = "it"
      expect(I18n.with_locale(:fr) { applicant.person.language }).to eq "it"
    end

    it "uses the request locale without submitted language" do
      expect(I18n.with_locale(:fr) { applicant.person.language }).to eq "fr"
    end

    it "adds the phone number as mobile number" do
      values[:phone_number] = "079 123 45 67"
      phone = applicant.person.phone_numbers.first
      expect(phone.number).to eq "079 123 45 67"
      expect(phone.category).to eq Event::Guest.phone_number_category
    end

    context "with accepted privacy policy" do
      let(:privacy_policy_accepted) { true }

      it "stores the acceptance on a new person" do
        attach_privacy_policy
        expect(applicant.person.privacy_policy_accepted_at).to be_present
      end

      it "stores no acceptance without a privacy policy to accept" do
        expect(applicant.person.privacy_policy_accepted_at).to be_nil
      end
    end
  end

  describe "#updates" do
    let(:person) { people(:top_leader) }

    around do |example|
      described_class.updatable_attributes = [:town]
      example.run
    ensure
      described_class.updatable_attributes = []
    end

    it "contains submitted updatable attributes of an existing person" do
      values.replace(email: person.email, town: "Thun", zip_code: "3600")
      expect(applicant.updates).to eq(town: "Thun")
    end

    it "is empty for a new person" do
      values[:town] = "Thun"
      expect(applicant.updates).to be_empty
    end

    it "is empty without updatable attributes" do
      described_class.updatable_attributes = []
      values.replace(email: person.email, town: "Thun")
      expect(applicant.updates).to be_empty
    end
  end
end
