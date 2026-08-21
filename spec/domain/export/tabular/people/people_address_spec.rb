# frozen_string_literal: true

#  Copyright (c) 2012-2026, Jungwacht Blauring Schweiz. This file is part of
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
      :additional_email_private, :additional_email_work, :additional_email_invoices, :additional_email_other,
      :phone_number_mobile, :phone_number_landline, :phone_number_work, :phone_number_other]
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

    describe "columns from ContactAccountCategory" do
      it "includes a column for every phone number category" do
        expect(attribute_labels).to have_key(:phone_number_landline)
        expect(attribute_labels).to have_key(:phone_number_mobile)
        expect(attribute_labels).to have_key(:phone_number_work)
        expect(attribute_labels[:phone_number_landline]).to eq "Telefonnummer Festnetz"
      end

      it "includes a column for every additional email category, including other" do
        expect(attribute_labels).to have_key(:additional_email_private)
        expect(attribute_labels).to have_key(:additional_email_work)
        expect(attribute_labels).to have_key(:additional_email_other)
        expect(attribute_labels[:additional_email_private]).to eq "Weitere E-Mail Privat"
        expect(attribute_labels[:additional_email_other]).to eq "Weitere E-Mail Andere"
      end
    end

    describe "Phone Numbers" do
      before do
        person.phone_numbers.create!(category: contact_account_categories(:phone_number_person_landline),
          number: "0791234567")
      end

      it "exports phone number value in the corresponding column" do
        expect(row(0)[attributes.index(:phone_number_landline)]).to eq "+41 79 123 45 67"
      end

      context "with multiple people" do
        let(:bottom_member) { people(:bottom_member) }
        let(:list) { [person, bottom_member] }

        before do
          bottom_member.phone_numbers.create!(category: contact_account_categories(:phone_number_person_mobile),
            number: "0791234569")
        end

        it "exports values for each person in the correct column" do
          expect(row(0)[attributes.index(:phone_number_landline)]).to eq "+41 79 123 45 67"
          expect(row(0)[attributes.index(:phone_number_mobile)]).to be_nil
          expect(row(1)[attributes.index(:phone_number_landline)]).to be_nil
          expect(row(1)[attributes.index(:phone_number_mobile)]).to eq "+41 79 123 45 69"
        end
      end

      context "public filtering" do
        before do
          person.phone_numbers.create!(category: contact_account_categories(:phone_number_person_mobile),
            number: "0791234000", public: false)
        end

        it "does not export non-public phone numbers in address export" do
          expect(row(0)[attributes.index(:phone_number_mobile)]).to be_nil
        end
      end
    end

    describe "Additional Emails" do
      before do
        person.additional_emails.create!(category: contact_account_categories(:additional_email_person_private),
          email: "privat@example.com")
      end

      it "exports additional email value in the corresponding column" do
        expect(row(0)[attributes.index(:additional_email_private)]).to eq "privat@example.com"
      end

      it "exports other-category entries as label:value pairs" do
        person.additional_emails.create!(category: contact_account_categories(:additional_email_person_other),
          label: "Ferien", email: "ferien@example.com")
        expect(row(0)[attributes.index(:additional_email_other)]).to eq "Ferien:ferien@example.com"
      end

      it "joins multiple other-category entries with semicolons" do
        person.additional_emails.create!(category: contact_account_categories(:additional_email_person_other),
          label: "Ferien", email: "ferien@example.com")
        person.additional_emails.create!(category: contact_account_categories(:additional_email_person_other),
          label: "Newsletter", email: "news@example.com")
        other = row(0)[attributes.index(:additional_email_other)]
        expect(other).to eq "Ferien:ferien@example.com;Newsletter:news@example.com"
      end

      context "public filtering" do
        before do
          person.additional_emails.create!(category: contact_account_categories(:additional_email_person_work),
            email: "secret@example.com", public: false)
        end

        it "does not export non-public emails in address export" do
          expect(row(0)[attributes.index(:additional_email_work)]).to be_nil
        end
      end
    end
  end
end
