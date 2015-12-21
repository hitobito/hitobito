# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Person::AddRequestMailer do

  before do
    SeedFu.quiet = true
    SeedFu.seed [Rails.root.join('db', 'seeds')]
  end

  let(:person) { Fabricate(Group::BottomLayer::Member.name, group: groups(:bottom_layer_two)).person }
  let(:requester) { Fabricate(Group::BottomLayer::Leader.name, group: groups(:bottom_layer_one)).person }
  let(:group) { groups(:bottom_layer_one) }

  let(:request) do
    Person::AddRequest::Group.create!(
      person: person,
      requester: requester,
      body: group,
      role_type: Group::BottomLayer::Member)
  end

  context 'ask person to add' do

    let(:mail) { Person::AddRequestMailer.ask_person_to_add(request) }

    subject { mail }
    
    its(:to)       { should == [person.email] }
    its(:sender)   { should =~ /#{requester.email.gsub('@','=')}/ }
    its(:subject)  { should == "Freigabe deiner Personendaten" }
    its(:body)     { should =~ /Hallo #{person.first_name}/ }
    its(:body)     { should =~ /#{requester.full_name} möchte dich/ }
    its(:body)     { should =~ /Bottom Layer 'Bottom One'/ }
    its(:body)     { should =~ /test.host\/groups\/#{group.id}/ }
    its(:body)     { should =~ /#{requester.full_name} hat folgende schreibberechtigten Rollen:/ }
    its(:body)     { should =~ /Leader in Bottom One/ }
    its(:body)     { should =~ /test.host\/people\/572407902\?body_id=#{group.id}&body_type=Group%3A%3ABottomLayer/ }

    it 'lists requester group roles with write permissions only' do
      Fabricate(Group::BottomLayer::Member.name, group: group, person: requester)
      Fabricate(Group::TopGroup::Leader.name, group: groups(:top_group), person: requester)
      expect(mail.body).to match('Leader in Bottom One, Leader in TopGroup')
    end

  end

  context 'ask responsibles to add person' do

    let(:leader) { Fabricate(Group::BottomLayer::Leader.name, group: groups(:bottom_layer_two)).person }
    let(:leader2) { Fabricate(Group::BottomLayer::Leader.name, group: groups(:bottom_layer_two)).person }
    let(:responsibles) { [leader, leader2] }

    let(:mail) { Person::AddRequestMailer.ask_responsibles(request, responsibles, group) }

    subject { mail }

    its(:to)       { should == [leader.email, leader2.email] }
    its(:sender)   { should =~ /#{requester.email.gsub('@','=')}/ }
    its(:subject)  { should == "Freigabe Personendaten" }
    its(:body)     { should =~ /Hallo #{leader.greeting_name}, #{leader2.greeting_name}/ }
    its(:body)     { should =~ /#{requester.full_name} möchte #{person.full_name} zu folgender/ }
    its(:body)     { should =~ /Bottom Layer 'Bottom One'/ }
    its(:body)     { should =~ /test.host\/groups\/#{group.id}/ }
    its(:body)     { should =~ /#{requester.full_name} hat folgende Rollen:/ }
    its(:body)     { should =~ /Leader in Bottom One/ }
    its(:body)     { should =~ /test.host\/groups\/#{group.id}\/person_add_requests/ }

  end

  context 'body url' do

    let(:mail) { Person::AddRequestMailer.send(:new) }

    it 'event url' do
      event = events(:top_course)
      group_id = event.groups.first.id
      expect(mail.send(:body_url, event)).to match(/http:/)
      expect(mail.send(:body_url, event)).to match(/\/groups\/#{group_id}\/events\/#{event.id}/)
    end

    it 'group url' do
      group = groups(:toppers)
      expect(mail.send(:body_url, group)).to match(/http:/)
      expect(mail.send(:body_url, group)).to match(/\/groups\/#{group.id}/)
    end

    it 'mailing list url' do
      list = mailing_lists(:leaders)
      group_id = list.group_id
      expect(mail.send(:body_url, list)).to match(/http:/)
      expect(mail.send(:body_url, list)).to match(/\/groups\/#{group_id}\/mailing_lists\/#{list.id}/)
    end

  end

end
