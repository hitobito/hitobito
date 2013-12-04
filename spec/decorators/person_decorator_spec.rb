# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe PersonDecorator, :draper_with_helpers do
  include Rails.application.routes.url_helpers

  let(:person) { people(:top_leader) }

  subject { PersonDecorator.new(person) }


  its(:full_label)   { should == 'Top Leader, Supertown' }
  its(:address_name) { should == '<strong>Top Leader</strong>' }

  context 'with town and birthday' do
    let(:person) do Fabricate(:person, first_name: 'Fra',
                                       last_name: 'Stuck',
                                       nickname: 'Schu',
                                       company_name: 'Coorp',
                                       birthday: '3.8.76',
                                       town: 'City') end

    its(:full_label)     { should == 'Fra Stuck / Schu, City (1976)' }
    its(:address_name)   { should == 'Coorp<br /><strong>Fra Stuck / Schu</strong>' }
    its(:additional_name) { should == 'Coorp' }
  end

  context 'as company' do
    let(:person) do Fabricate(:person, first_name: 'Fra',
                                       last_name: 'Stuck',
                                       nickname: 'Schu',
                                       company_name: 'Coorp',
                                       birthday: '3.8.76',
                                       town: 'City',
                                       company: true) end

    its(:full_label)      { should == 'Coorp, City (Fra Stuck)' }
    its(:address_name)    { should == '<strong>Coorp</strong><br />Fra Stuck' }
    its(:additional_name) { should == 'Fra Stuck' }
  end

  context 'roles grouped' do
    let(:roles_grouped) { PersonDecorator.new(person).roles_grouped }

    before do
      Fabricate(Group::TopGroup::Member.name.to_sym, group: groups(:top_group), person: person)
      Fabricate(Group::BottomLayer::Member.name.to_sym, group: groups(:bottom_layer_one), person: person)
    end

    specify do
      roles_grouped.should have(2).items
      roles_grouped[groups(:top_group)].should have(2).items
      roles_grouped[groups(:bottom_layer_one)].should have(1).items
    end
  end

end
