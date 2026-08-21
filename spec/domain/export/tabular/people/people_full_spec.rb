#  Copyright (c) 2012-2026, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Export::Tabular::People::PeopleFull do
  let(:person) { people(:top_leader) }
  let(:scope) { Person.where(id: person.id) }
  let(:people_list) { Export::Tabular::People::PeopleFull.new(scope) }

  subject { people_list }

  its(:attributes) do
    expected = [:first_name, :last_name, :nickname, :company_name, :company, :email,
      :address_care_of, :street, :housenumber, :postbox, :zip_code, :town, :country,
      :layer_group, :roles, :gender, :birthday, :additional_information, :language, :tags,
      :additional_email_private, :additional_email_work, :additional_email_invoices, :additional_email_other,
      :phone_number_mobile, :phone_number_landline, :phone_number_work, :phone_number_other,
      :social_account_facebook, :social_account_x_twitter, :social_account_website, :social_account_other]
    should match_array expected
    should eq expected
  end

  context "#attribute_labels" do
    subject { people_list.attribute_labels }

    its([:roles]) { should eq "Rollen" }

    its([:company]) { should eq "Firma" }
    its([:company_name]) { should eq "Firmenname" }

    context "social accounts" do
      it "includes social account categories as columns" do
        expect(subject[:social_account_facebook]).to eq "Social Media Adresse Facebook"
        expect(subject[:social_account_x_twitter]).to eq "Social Media Adresse X (Twitter)"
        expect(subject[:social_account_website]).to eq "Social Media Adresse Webseite"
      end
    end

    context "additional_addresses" do
      before do
        allow(Settings.additional_address).to receive(:enabled).and_return(true)
        person.additional_addresses << Fabricate.build(:additional_address,
          category: contact_account_categories(:additional_address_person_work), 
          first_name: "Foo", last_name: "Bar", street: "def", uses_contactable_name: false)
      end

      its([:additional_address_work]) { should eq "Weitere Adresse Arbeit" }

      it "prefixes address values with names" do
        # rubocop:todo Layout/LineLength
        expect(people_list.data_rows.to_a.first[subject.keys.index(:additional_address_work)]).to start_with("Foo Bar, def")
        # rubocop:enable Layout/LineLength
      end

      it "exports other-category entries as label:value pairs" do
        person.additional_addresses << Fabricate.build(:additional_address,
          category: contact_account_categories(:additional_address_person_other), label: "Ferien", street: "abc")
        data = people_list.data_rows.to_a.first
        other = data[subject.keys.index(:additional_address_other)]
        expect(other).to start_with("Ferien:Top Leader, abc")
      end
    end

    it "includes non-public contact accounts in full export" do
      person.phone_numbers.create!(category: contact_account_categories(:phone_number_person_mobile),
        number: "0791234000", public: false)
      person.additional_emails.create!(category: contact_account_categories(:additional_email_person_work),
        email: "secret@example.com", public: false)
      person.social_accounts.create!(category: contact_account_categories(:social_account_person_facebook),
        name: "secret_fb", public: false)
      data = people_list.data_rows.to_a.first
      expect(data[subject.keys.index(:phone_number_mobile)]).to eq "+41 79 123 40 00"
      expect(data[subject.keys.index(:additional_email_work)]).to eq "secret@example.com"
      expect(data[subject.keys.index(:social_account_facebook)]).to eq "secret_fb"
    end

    context "qualification_kinds" do
      let(:qualification_kind) { qualification_kinds(:sl) }
      let!(:qualification) { Fabricate(:qualification, person:, qualification_kind:) }

      it "shows only one header per kind for current locale" do
        qualification_kind.label_translations = {de: "Super Lead DE", fr: "Super Lead FR", it: "Super Lead IT"}
        qualification_kind.save!
        I18n.locale = :fr
        expect(subject[:"qualification_kind_#{qualification_kind.id}"]).to eq("Type de qualification Super Lead FR")
      end
    end
  end
end
