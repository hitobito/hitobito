#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Export::Tabular::People::PersonRow do
  let(:person) { people(:top_leader) }
  let(:row) { Export::Tabular::People::PersonRow.new(person) }

  subject { row }

  context "standard attributes" do
    it { expect(row.fetch(:id)).to eq person.id }
    it { expect(row.fetch(:first_name)).to eq "Top" }
  end

  context "phone numbers" do
    before { person.phone_numbers << PhoneNumber.new(label: "foobar", number: 321) }

    it { expect(row.fetch(:phone_number_foobar)).to eq "321" }
  end

  context "social accounts" do
    before { person.social_accounts << SocialAccount.new(label: "foo oder bar!", name: "asdf") }

    it { expect(row.fetch(:"social_account_foo oder bar!")).to eq "asdf" }
  end

  context "additional_addresses" do
    let(:address_attrs) { {street: "Langestrasse", housenumber: 3, zip_code: 8000, town: "Zürich", country: "CH"} }

    before do
      person.additional_addresses << Fabricate.build(:additional_address, address_attrs.merge(label: "Rechnung"))
      person.additional_addresses << Fabricate.build(:additional_address,
        address_attrs.merge(label: "Weitere", housenumber: 4, name: "test", uses_contactable_name: false))
    end

    it { expect(row.fetch(:additional_address_rechnung)).to eq "Top Leader, Langestrasse 3, 8000 Zürich" }

    it { expect(row.fetch(:additional_address_weitere)).to eq "test, Langestrasse 4, 8000 Zürich" }
  end

  context "country" do
    before { person.country = "IT" }

    it { expect(row.fetch(:country)).to eq "Italien" }
  end

  context "roles" do
    it { expect(row.fetch(:roles)).to eq "Leader Top / TopGroup" }

    context "multiple roles" do
      let(:group) { groups(:bottom_group_one_one) }

      before { Fabricate(Group::BottomGroup::Member.name.to_s, group: group, person: person) }

      it {
        expect(row.fetch(:roles).split(", ")).to match_array ["Leader Top / TopGroup", "Member Bottom One / Group 11"]
      }
    end
  end

  context "tags" do
    before do
      person.tag_list = "lorem: ipsum, loremipsum"
      person.save
    end

    it { expect(row.fetch(:tags)).to eq "lorem:ipsum, loremipsum" }
  end

  context "qualifications" do
    let!(:qualification) { Fabricate(:qualification, qualified_at: 1.day.ago, person:) }

    it do
      expect(row.fetch(:"qualification_kind_#{qualification.qualification_kind.id}")).to eq qualification.finish_at.to_s
    end
  end
end
