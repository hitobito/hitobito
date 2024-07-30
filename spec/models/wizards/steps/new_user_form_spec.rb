# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of hitobito and licensed under the
#  Affero General Public License version 3 or later. See the COPYING file at the top-level directory
#  or at https://github.com/hitobito/hitobito.

require "spec_helper"

describe Wizards::Steps::NewUserForm do
  let(:group) { Fabricate.build(:group) }
  let(:wizard) { Wizards::RegisterNewUserWizard.new(group: group) }

  subject(:form) { described_class.new(wizard) }

  describe "validations" do
    it "is valid when first and last_name are set" do
      form.first_name = "test"
      form.last_name = "test"
      expect(form).to be_valid
    end

    it "is invalid when first_name is blank" do
      form.last_name = "test"
      expect(form).not_to be_valid
      expect(form).to have(1).error_on(:first_name)
    end

    it "is invalid when last_name is blank" do
      form.first_name = "test"
      expect(form).not_to be_valid
      expect(form).to have(1).error_on(:last_name)
    end

    describe "company" do
      it "is invalid if company flag but no company name is supplied" do
        form.first_name = "test"
        form.last_name = "test"
        form.company = true
        expect(form).not_to be_valid
        expect(form).to have(1).error_on(:company_name)
      end

      it "is valid if company flag but and company name are present" do
        form.first_name = "test"
        form.last_name = "test"
        form.company = true
        form.company_name = "test"
        expect(form).to be_valid
      end
    end

    context "group with adult_consent required" do
      before do
        form.first_name = "test"
        form.last_name = "test"
        group.self_registration_require_adult_consent = true
      end

      it "is valid if adult_consent is missing" do
        expect(form).to be_valid
      end

      it "is valid if adult_consent is accepted" do
        form.adult_consent = true
        expect(form).to be_valid
      end

      it "is invalid if adult_consent is not accepted" do
        form.adult_consent = false
        expect(form).not_to be_valid
        expect(form).to have(1).error_on(:adult_consent)
      end
    end

    context "group with privacy policy" do
      let(:group) { groups(:top_group) }
      let(:error_message) { form.errors.full_messages.first }

      before do
        form.first_name = "test"
        form.last_name = "test"

        file = Rails.root.join("spec", "fixtures", "files", "images", "logo.png")
        image = ActiveStorage::Blob.create_and_upload!(io: File.open(file, "rb"),
          filename: "logo.png",
          content_type: "image/png").signed_id
        group.layer_group.update(privacy_policy: image,
          privacy_policy_title: "Privacy Policy Top Layer")
      end

      it "is valid if privacy_policy_accepted is accepted" do
        form.privacy_policy_accepted = true
        expect(form).to be_valid
      end

      it "is invalid if privacy_policy_accepted is missing" do
        expect(form).not_to be_valid
        expect(form).to have(1).error_on(:base)
        expect(error_message).to eq "Um die Registrierung abzuschliessen, muss der Datenschutzerklärung zugestimmt werden."
      end

      it "is invalid if privacy_policy_accepted is not accepted" do
        form.privacy_policy_accepted = false
        expect(form).not_to be_valid
      end
    end
  end
end
