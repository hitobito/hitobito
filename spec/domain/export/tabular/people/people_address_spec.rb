#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz. This file is part of
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
    is_expected.to == [:first_name, :last_name, :nickname, :company_name, :company, :email, :address,
                       :zip_code, :town, :country, :gender, :birthday, :layer_group, :roles, :tags,]
  end

  context "standard attributes" do
    context "#attribute_labels" do
      subject { people_list.attribute_labels }

      its([:id]) { is_expected.to be_blank }
      its([:roles]) { is_expected.to eq "Rollen" }
      its([:first_name]) { is_expected.to eq "Vorname" }
    end

    context "key list" do
      subject { people_list.attribute_labels.keys.join(" ") }

      it { is_expected.not_to match(/phone/) }
      it { is_expected.not_to match(/social_account/) }
    end
  end

  context "phone_numbers" do
    before { person.phone_numbers << PhoneNumber.new(label: "Privat", number: 321) }

    subject { people_list.attribute_labels }

    its([:phone_number_privat]) { is_expected.to eq "Telefonnummer Privat" }
    its([:phone_number_mobil]) { is_expected.to be_nil }

    context "different labels" do
      let(:other) { people(:bottom_member) }
      let(:list) { [person, other] }

      before do
        other.phone_numbers << PhoneNumber.new(label: "Foobar", number: 321)
        person.phone_numbers << PhoneNumber.new(label: "Privat", number: 321)
      end

      its([:phone_number_privat]) { is_expected.to eq "Telefonnummer Privat" }
      its([:phone_number_foobar]) { is_expected.to eq "Telefonnummer Foobar" }
    end

    context "blank label is not exported" do
      before { person.phone_numbers << PhoneNumber.new(label: "", number: 321) }

      its(:keys) { is_expected.to_not include :phone_number_ }
    end
  end
end
