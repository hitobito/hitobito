# encoding: utf-8

#  Copyright (c) 2012-2014, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'
require 'csv'

describe Export::Csv::People::PersonRow do

  before do
    PeopleRelation.kind_opposites['parent'] = 'child'
    PeopleRelation.kind_opposites['child'] = 'parent'
  end

  after do
    PeopleRelation.kind_opposites.clear
  end

  let(:person) { people(:top_leader) }
  let(:row) { Export::Csv::People::PersonRow.new(person) }

  subject { row }

  context 'standard attributes' do
    it { row.fetch(:id).should eq person.id }
    it { row.fetch(:first_name).should eq 'Top' }
  end

  context 'roles' do
    it { row.fetch(:roles).should eq 'Leader Top / TopGroup' }

    context 'multiple roles' do
      let(:group) { groups(:bottom_group_one_one) }
      before { Fabricate(Group::BottomGroup::Member.name.to_s, group: group, person: person) }

      it { row.fetch(:roles).should eq 'Member Bottom One / Group 11, Leader Top / TopGroup' }
    end
  end

  context 'phone numbers' do
    before { person.phone_numbers << PhoneNumber.new(label: 'foobar', number: 321) }
    it { row.fetch(:phone_number_foobar).should eq '321' }
  end

  context 'social accounts' do
    before { person.social_accounts << SocialAccount.new(label: 'foo oder bar!', name: 'asdf') }
    it { row.fetch(:'social_account_foo oder bar!').should eq 'asdf' }
  end

  context 'people relations' do
    before { person.relations_to_tails << PeopleRelation.new(tail_id: people(:bottom_member).id, kind: 'parent') }
    it { row.fetch(:people_relation_parent).should eq 'Bottom Member' }
  end

end
