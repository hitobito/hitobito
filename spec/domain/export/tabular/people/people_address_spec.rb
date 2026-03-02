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
      :layer_group, :roles,
      :additional_email_privat, :additional_email_arbeit, :additional_email_vater,
      :additional_email_mutter, :additional_email_andere, :additional_email_custom_label,
      :phone_number_privat, :phone_number_mobil, :phone_number_arbeit,
      :phone_number_vater, :phone_number_mutter, :phone_number_fax, :phone_number_andere]
  end

  context "standard attributes" do
    context "#attribute_labels" do
      subject { people_list.attribute_labels }

      its([:id]) { should be_blank }
      its([:roles]) { should eq "Rollen" }
      its([:first_name]) { should eq "Vorname" }
    end
  end

  describe "account labels" do
    def row(index) = people_list.data_rows.to_a[index]

    let(:attributes) { people_list.attributes }
    let(:attribute_labels) { people_list.attribute_labels }

    describe "fixed columns from predefined_labels" do
      it "includes all predefined phone number labels as columns" do
        expect(attribute_labels).to have_key(:phone_number_privat)
        expect(attribute_labels).to have_key(:phone_number_mobil)
        expect(attribute_labels).to have_key(:phone_number_arbeit)
        expect(attribute_labels[:phone_number_privat]).to eq "Telefonnummer Privat"
      end

      it "does not include a free text column for phone numbers" do
        expect(attribute_labels).not_to have_key(:phone_number_custom_label)
      end

      it "includes all predefined additional email labels as columns" do
        expect(attribute_labels).to have_key(:additional_email_privat)
        expect(attribute_labels).to have_key(:additional_email_arbeit)
        expect(attribute_labels[:additional_email_privat]).to eq "Weitere E-Mail Privat"
      end

      it "includes a free text column for additional emails" do
        expect(attribute_labels).to have_key(:additional_email_custom_label)
        expect(attribute_labels[:additional_email_custom_label]).to eq "Weitere E-Mails Freitext"
      end
    end

    describe "Phone Numbers" do
      before { PhoneNumber.create!(contactable: person, label: "Privat", number: "0791234567") }

      it "exports phone number value in the corresponding column" do
        expect(row(0)[attributes.index(:phone_number_privat)]).to eq "+41 79 123 45 67"
      end

      it "joins multiple phone numbers with same label using semicolon" do
        PhoneNumber.create!(contactable: person, label: "Privat", number: "0791234568")
        expect(row(0)[attributes.index(:phone_number_privat)]).to eq "+41 79 123 45 67;+41 79 123 45 68"
      end

      context "with multiple people" do
        let(:bottom_member) { people(:bottom_member) }
        let(:list) { [person, bottom_member] }

        before do
          PhoneNumber.create!(contactable: bottom_member, label: "Mobil", number: "0791234569")
        end

        it "exports values for each person in the correct column" do
          expect(row(0)[attributes.index(:phone_number_privat)]).to eq "+41 79 123 45 67"
          expect(row(0)[attributes.index(:phone_number_mobil)]).to be_nil
          expect(row(1)[attributes.index(:phone_number_privat)]).to be_nil
          expect(row(1)[attributes.index(:phone_number_mobil)]).to eq "+41 79 123 45 69"
        end
      end

      context "public filtering" do
        before do
          PhoneNumber.create!(contactable: person, label: "Mobil", number: "0791234000", public: false)
        end

        it "does not export non-public phone numbers in address export" do
          expect(row(0)[attributes.index(:phone_number_mobil)]).to be_nil
        end
      end
    end

    describe "Additional Emails" do
      before { AdditionalEmail.create!(contactable: person, label: "Privat", email: "privat@example.com") }

      it "exports additional email value in the corresponding column" do
        expect(row(0)[attributes.index(:additional_email_privat)]).to eq "privat@example.com"
      end

      it "joins multiple additional emails with same label using semicolon" do
        AdditionalEmail.create!(contactable: person, label: "Privat", email: "privat2@example.com")
        values = row(0)[attributes.index(:additional_email_privat)]
        expect(values).to eq "privat@example.com;privat2@example.com"
      end

      it "exports non-predefined labels in the free text column" do
        AdditionalEmail.create!(contactable: person, label: "Ferien", email: "ferien@example.com")
        expect(row(0)[attributes.index(:additional_email_custom_label)]).to eq "Ferien:ferien@example.com"
      end

      it "joins multiple non-predefined entries with semicolons in free text column" do
        AdditionalEmail.create!(contactable: person, label: "Ferien", email: "ferien@example.com")
        AdditionalEmail.create!(contactable: person, label: "Newsletter", email: "news@example.com")
        custom_label = row(0)[attributes.index(:additional_email_custom_label)]
        expect(custom_label).to eq "Ferien:ferien@example.com;Newsletter:news@example.com"
      end

      context "public filtering" do
        before do
          AdditionalEmail.create!(contactable: person, label: "Arbeit", email: "secret@example.com", public: false)
        end

        it "does not export non-public emails in address export" do
          expect(row(0)[attributes.index(:additional_email_arbeit)]).to be_nil
        end
      end
    end
  end
end
