# encoding: utf-8

#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Export::Tabular::People::PersonRow do

  before do
    PeopleRelation.kind_opposites["parent"] = "child"
    PeopleRelation.kind_opposites["child"] = "parent"
  end

  after do
    PeopleRelation.kind_opposites.clear
  end

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
    it { expect(row.fetch(:'social_account_foo oder bar!')).to eq "asdf" }
  end

  context "people relations" do
    before { person.relations_to_tails << PeopleRelation.new(tail_id: people(:bottom_member).id, kind: "parent") }
    it { expect(row.fetch(:people_relation_parent)).to eq "Bottom Member" }
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

      it { expect(row.fetch(:roles)).to eq "Member Bottom One / Group 11, Leader Top / TopGroup" }
    end
  end

  context "tags" do
    before do
      person.tag_list = "lorem: ipsum, loremipsum"
      person.save
    end
    it { expect(row.fetch(:tags)).to eq "lorem:ipsum, loremipsum"}
  end

end
