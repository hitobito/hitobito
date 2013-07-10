require 'spec_helper'

describe PersonDecorator, :draper_with_helpers do
  include Rails.application.routes.url_helpers

  let(:person) { people(:top_leader) }

  subject { PersonDecorator.new(person) }


  its(:full_label)   { should == "Leader Top, Supertown" }
  its(:address_name) { should == '<strong>Leader Top</strong>' }

  context "with town and birthday" do
    let(:person) { Fabricate(:person, first_name: 'Fra',
                                      last_name: 'Stuck',
                                      nickname: 'Schu',
                                      company_name: 'Coorp',
                                      birthday: '3.8.76',
                                      town: 'City') }

    its(:full_label)     { should == "Stuck Fra / Schu, City (1976)"}
    its(:address_name)   { should == "Coorp<br /><strong>Stuck Fra / Schu</strong>" }
    its(:additional_name) { should == 'Coorp' }
  end

  context "as company" do
    let(:person) { Fabricate(:person, first_name: 'Fra',
                                      last_name: 'Stuck',
                                      nickname: 'Schu',
                                      company_name: 'Coorp',
                                      birthday: '3.8.76',
                                      town: 'City',
                                      company: true) }

    its(:full_label)      { should == "Coorp, City (Stuck Fra)"}
    its(:address_name)    { should == "<strong>Coorp</strong><br />Stuck Fra" }
    its(:additional_name) { should == 'Stuck Fra' }
  end

  context "roles grouped" do
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
