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
      :layer_group, :roles, :gender, :birthday, :additional_information, :language, :tags]
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
      before { person.social_accounts << SocialAccount.new(label: "Webseite", name: "foo.bar") }

      its([:social_account_webseite]) { should eq "Social Media Adresse Webseite" }
    end

    context "additional_addresses" do
      before do
        person.additional_addresses << Fabricate.build(:additional_address, label: "Rechnung", street: "abc")
        person.additional_addresses << Fabricate.build(:additional_address, label: "Arbeit", name: "Foo Bar", street: "def", uses_contactable_name: false)
      end

      its([:additional_address_rechnung]) { should eq "Weitere Adresse Rechnung" }
      its([:additional_address_arbeit]) { should eq "Weitere Adresse Arbeit" }

      it "prefixes address values with names" do
        expect(people_list.data_rows.to_a.first[subject.keys.index(:additional_address_rechnung)]).to start_with("Top Leader, abc")
        expect(people_list.data_rows.to_a.first[subject.keys.index(:additional_address_arbeit)]).to start_with("Foo Bar, def")
      end
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
