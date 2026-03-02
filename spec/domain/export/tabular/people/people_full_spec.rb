#  Copyright (c) 2012-2024, Jungwacht Blauring Schweiz. This file is part of
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
      :additional_email_privat, :additional_email_arbeit, :additional_email_vater,
      :additional_email_mutter, :additional_email_andere, :additional_email_custom_label,
      :phone_number_privat, :phone_number_mobil, :phone_number_arbeit,
      :phone_number_vater, :phone_number_mutter, :phone_number_fax, :phone_number_andere,
      :social_account_facebook, :social_account_msn, :social_account_skype,
      :social_account_twitter, :social_account_webseite, :social_account_andere,
      :social_account_custom_label]
    should match_array expected
    should eq expected
  end

  context "#attribute_labels" do
    subject { people_list.attribute_labels }

    its([:roles]) { should eq "Rollen" }
    its([:social_account_website]) { should be_blank }

    its([:company]) { should eq "Firma" }
    its([:company_name]) { should eq "Firmenname" }

    context "social accounts" do
      it "includes predefined social account labels as columns" do
        expect(subject[:social_account_facebook]).to eq "Social Media Adresse Facebook"
        expect(subject[:social_account_webseite]).to eq "Social Media Adresse Webseite"
      end
    end

    context "additional_addresses" do
      before do
        allow(Settings.additional_address).to receive(:enabled).and_return(true)
        person.additional_addresses << Fabricate.build(:additional_address, label: "Arbeit", name: "Foo Bar",
          street: "def", uses_contactable_name: false)
      end

      its([:additional_address_arbeit]) { should eq "Weitere Adresse Arbeit" }

      it "prefixes address values with names" do
        # rubocop:todo Layout/LineLength
        expect(people_list.data_rows.to_a.first[subject.keys.index(:additional_address_arbeit)]).to start_with("Foo Bar, def")
        # rubocop:enable Layout/LineLength
      end

      it "exports non-predefined labels in the free text column" do
        person.additional_addresses << Fabricate.build(:additional_address, label: "Ferien", street: "abc")
        data = people_list.data_rows.to_a.first
        custom_label = data[subject.keys.index(:additional_address_custom_label)]
        expect(custom_label).to start_with("Ferien:Top Leader, abc")
      end
    end

    it "includes non-public contact accounts in full export" do
      person.phone_numbers.create!(label: "Mobil", number: "0791234000", public: false)
      person.additional_emails.create!(label: "Arbeit", email: "secret@example.com", public: false)
      person.social_accounts.create!(label: "Facebook", name: "secret_fb", public: false)
      data = people_list.data_rows.to_a.first
      expect(data[subject.keys.index(:phone_number_mobil)]).to eq "+41 79 123 40 00"
      expect(data[subject.keys.index(:additional_email_arbeit)]).to eq "secret@example.com"
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
