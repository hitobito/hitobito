# frozen_string_literal: true

#  Copyright (c) 2012-2024, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Export::Tabular::People::PeopleAddress do
  let(:person) { people(:top_leader) }
  let(:list) { [person] }
  let(:people_list) { Export::Tabular::People::PeopleAddress.new(list) }

  subject { people_list }

  its(:attributes) do
    should == [:first_name, :last_name, :nickname, :company_name, :company, :email,
      :address_care_of, :street, :housenumber, :postbox, :zip_code, :town, :country,
      :layer_group, :roles]
  end

  context "standard attributes" do
    context "#attribute_labels" do
      subject { people_list.attribute_labels }

      its([:id]) { should be_blank }
      its([:roles]) { should eq "Rollen" }
      its([:first_name]) { should eq "Vorname" }
    end

    context "key list" do
      subject { people_list.attribute_labels.keys.join(" ") }

      it { is_expected.not_to match(/phone/) }
      it { is_expected.not_to match(/social_account/) }
    end
  end

  describe "account labels" do
    def row(index) = people_list.data_rows.to_a[index]

    let(:attributes) { people_list.attributes }
    let(:attribute_labels) { people_list.attribute_labels }

    describe "Phone Numbers" do
      before { PhoneNumber.create!(contactable: person, label: "Privat", number: "0791234567") }

      it "includes phone number" do
        expect(attribute_labels.keys).to have(13).items
        expect(attribute_labels).to have_key(:phone_number_privat)
        expect(attribute_labels[:phone_number_privat]).to eq "Telefonnummer Privat"
        expect(row(0)[attributes.index(:phone_number_privat)]).to eq "+41 79 123 45 67"
      end

      it "includes multiple phone numbers" do
        PhoneNumber.create!(contactable: person, label: "Foobar", number: "0791234568")
        expect(attribute_labels.keys).to have(14).items
        expect(attribute_labels[:phone_number_foobar]).to eq "Telefonnummer Foobar"
        expect(row(0)[attributes.index(:phone_number_privat)]).to eq "+41 79 123 45 67"
        expect(row(0)[attributes.index(:phone_number_foobar)]).to eq "+41 79 123 45 68"
      end

      it "does not include phone number with blank label" do
        number = PhoneNumber.create!(contactable: person, label: "Foobar", number: "0791234568")
        number.update_columns(label: "")
        expect(attribute_labels.keys).to have(13).items
        expect(attribute_labels).not_to have_key(:phone_number_)
      end

      context "with multiple people" do
        let(:bottom_member) { people(:bottom_member) }
        let(:other) { Fabricate(:person) }
        let(:list) { [person, bottom_member] }

        before do
          PhoneNumber.create!(contactable: person, label: "Foobar", number: "0791234568")
          PhoneNumber.create!(contactable: bottom_member, label: "Foobar", number: "0791234569")
          PhoneNumber.create!(contactable: other, label: "Other", number: "0791234560")
        end

        it "includes phone number of all in list" do
          expect(row(0)[attributes.index(:phone_number_privat)]).to eq "+41 79 123 45 67"
          expect(row(0)[attributes.index(:phone_number_foobar)]).to eq "+41 79 123 45 68"
          expect(row(1)[attributes.index(:phone_number_privat)]).to be_nil
          expect(row(1)[attributes.index(:phone_number_foobar)]).to eq "+41 79 123 45 69"
        end

        it "does not include phone number of person not in list" do
          expect(subject.attribute_labels).not_to have_key(:phone_number_other)
        end
      end
    end

    describe "Additional Emails" do
      before { AdditionalEmail.create!(contactable: person, label: "Privat", email: "privat@example.com") }

      it "includes additional email" do
        expect(attribute_labels.keys).to have(13).items
        expect(attribute_labels).to have_key(:additional_email_privat)
        expect(attribute_labels[:additional_email_privat]).to eq "Weitere E-Mail Privat"
        expect(row(0)[attributes.index(:additional_email_privat)]).to eq "privat@example.com"
      end

      it "includes multiple additional emails" do
        AdditionalEmail.create!(contactable: person, label: "Foobar", email: "foobar@example.com")
        expect(attribute_labels.keys).to have(14).items
        expect(attribute_labels[:additional_email_foobar]).to eq "Weitere E-Mail Foobar"
        expect(row(0)[attributes.index(:additional_email_privat)]).to eq "privat@example.com"
        expect(row(0)[attributes.index(:additional_email_foobar)]).to eq "foobar@example.com"
      end

      it "does not include additional email with blank label" do
        email = AdditionalEmail.create!(contactable: person, label: "Foobar", email: "foobar@example.com")
        email.update_columns(label: "")
        expect(attribute_labels.keys).to have(13).items
        expect(attribute_labels).not_to have_key(:additional_email_)
      end

      context "with multiple people" do
        let(:bottom_member) { people(:bottom_member) }
        let(:other) { Fabricate(:person) }
        let(:list) { [person, bottom_member] }

        before do
          AdditionalEmail.create!(contactable: person, label: "Foobar", email: "foobar@example.com")
          AdditionalEmail.create!(contactable: bottom_member, label: "Foobar", email: "foobar2@example.com")
          AdditionalEmail.create!(contactable: other, label: "Other", email: "other@example.com")
        end

        it "includes additional email of all in list" do
          expect(row(0)[attributes.index(:additional_email_privat)]).to eq "privat@example.com"
          expect(row(0)[attributes.index(:additional_email_foobar)]).to eq "foobar@example.com"
          expect(row(1)[attributes.index(:additional_email_privat)]).to be_nil
          expect(row(1)[attributes.index(:additional_email_foobar)]).to eq "foobar2@example.com"
        end

        it "does not include additional email of person not in list" do
          expect(subject.attribute_labels).not_to have_key(:additional_email_other)
        end
      end
    end
  end
end
