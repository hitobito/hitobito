# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

require "spec_helper"
require_relative "contactable_shared_examples"

describe Contactable do
  let(:street) { "Main Street" }
  let(:housenumber) { "23a" }
  let(:zip_code) { 1234 }
  let(:town) { "Jamestown" }

  context "#invoice_address" do
    let(:group) { groups(:top_layer) }

    it "returns additional_email with invoice flag" do
      group.additional_emails.create!(email: "foo@bar.com", contactable: group, label: "Privat", invoices: true)
      expect(group.invoice_email).to eq "foo@bar.com"
    end

    it "returns group primary email when no additional_email with invoice_flag" do
      group.additional_emails.create!(email: "foo@bar.com", contactable: group, label: "Privat", invoices: false)
      expect(group.invoice_email).to eq group.email
    end
  end

  describe "category uniqueness" do
    context "PhoneNumber on Person" do
      it_behaves_like "enforces category uniqueness per contactable",
        factory: :phone_number,
        factory_attrs: {number: "+41 78 000 00 00"},
        contactable: -> { people(:top_leader) },
        other_contactable: -> { people(:bottom_member) },
        unique_category: :phone_number_person_mobile,
        other_unique_category: :phone_number_person_landline,
        non_unique_category: :phone_number_person_other
    end

    context "SocialAccount on Person" do
      it_behaves_like "enforces category uniqueness per contactable",
        factory: :social_account,
        factory_attrs: {name: "myprofile"},
        contactable: -> { people(:top_leader) },
        other_contactable: -> { people(:bottom_member) },
        unique_category: :social_account_person_facebook,
        other_unique_category: :social_account_person_x_twitter,
        non_unique_category: :social_account_person_other
    end

    context "AdditionalEmail on Person" do
      it_behaves_like "enforces category uniqueness per contactable",
        factory: :additional_email,
        factory_attrs: {email: "foo@example.com"},
        contactable: -> { people(:top_leader) },
        other_contactable: -> { people(:bottom_member) },
        unique_category: :additional_email_person_private,
        other_unique_category: :additional_email_person_work,
        non_unique_category: :additional_email_person_other
    end

    context "AdditionalAddress on Person" do
      it_behaves_like "enforces category uniqueness per contactable",
        factory: :additional_address,
        factory_attrs: {street: "Bahnhofstrasse", zip_code: "8000", town: "Zürich", country: "CH"},
        contactable: -> { people(:top_leader) },
        other_contactable: -> { people(:bottom_member) },
        unique_category: :additional_address_person_work,
        other_unique_category: :additional_address_person_invoices,
        non_unique_category: :additional_address_person_other
    end

    context "PhoneNumber on Group" do
      it_behaves_like "enforces category uniqueness per contactable",
        factory: :phone_number,
        factory_attrs: {number: "+41 78 000 00 00"},
        contactable: -> { groups(:top_layer) },
        other_contactable: -> { groups(:bottom_layer_one) },
        unique_category: :phone_number_group_office,
        other_unique_category: :phone_number_group_mobile,
        non_unique_category: :phone_number_group_other
    end
  end

  describe Person do
    it_behaves_like "fixing common autocomplete issues", :postbox
    it_behaves_like "fixing common autocomplete issues", :address_care_of
  end

  describe Group do
    it_behaves_like "fixing common autocomplete issues", :postbox
    it_behaves_like "fixing common autocomplete issues", :address_care_of
  end
end
