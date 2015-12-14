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

  let(:request_body_label) { 'Kurs Foo' }
  let(:requester_name) { requester.full_name }
  let(:requester_group_roles) { 'Bund Geschäftsleitung' }

  let(:mail) { Person::AddRequestMailer.ask_person_to_add(request, request_body_label, requester_name, requester_group_roles) }

  subject { mail }

  its(:to)       { should == [person.email] }
  its(:sender)   { should =~ /#{requester.email.gsub('@','=')}/ }
  its(:subject)  { should == "Freigabe deiner Personendaten" }
  its(:body)     { should =~ /Hallo #{person.first_name}/ }
  its(:body)     { should =~ /#{requester.full_name} möchte dich/ }
  its(:body)     { should =~ /Kurs Foo/ }
  its(:body)     { should =~ /#{requester.full_name} gehört zu folgenden Gruppen:/ }
  its(:body)     { should =~ /Bund Geschäftsleitung/ }
  its(:body)     { should =~ /test.host\/people\/572407902/ }

end
