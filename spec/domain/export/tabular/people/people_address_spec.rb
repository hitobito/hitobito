# frozen_string_literal: true

#  Copyright (c) 2012-2023, Jungwacht Blauring Schweiz. This file is part of
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
    should == [:first_name, :last_name, :nickname, :company_name, :company, :email, :address,
      :zip_code, :town, :country, :layer_group, :roles]
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

  context "phone_numbers" do
    before { PhoneNumber.create!(contactable: person, label: "Privat", number: "0791234567") }

    subject { people_list.attribute_labels }

    its([:phone_number_privat]) { should eq "Telefonnummer Privat" }
    its([:phone_number_mobil]) { should be_nil }

    context "different labels" do
      let(:other) { people(:bottom_member) }
      let(:list) { [person, other] }

      before do
        PhoneNumber.create!(contactable: other, label: "Foobar", number: "0791234567")
        PhoneNumber.create!(contactable: person, label: "Privat", number: "0791234567")
      end

      its([:phone_number_privat]) { should eq "Telefonnummer Privat" }
      its([:phone_number_foobar]) { should eq "Telefonnummer Foobar" }
    end

    context "blank label is not exported" do
      before do
        number = PhoneNumber.create!(contactable: person, label: "label", number: "0791234567")
        PhoneNumber.where(id: number.id).update_all(label: "")
      end

      its(:keys) { should_not include :phone_number_ }
    end
  end
end
