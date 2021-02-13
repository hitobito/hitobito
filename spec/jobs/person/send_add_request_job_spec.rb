# encoding: utf-8

#  Copyright (c) 2012-2015, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Person::SendAddRequestJob do
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

  let(:job) { Person::SendAddRequestJob.new(request) }

  it "sends email to person if it has a login password" do
    person.update_column(:encrypted_password, "yadayada")
    mail = double("mail")
    expect(mail).to receive(:deliver_now)
    expect(Person::AddRequestMailer).to receive(:ask_person_to_add).and_return(mail)
    expect(Person::AddRequestMailer).not_to receive(:ask_responsibles)
    job.perform
  end

  it "sends no email to person if it has no login password" do
    person.update_column(:encrypted_password, nil)
    expect(Person::AddRequestMailer).not_to receive(:ask_person_to_add)
    expect(Person::AddRequestMailer).not_to receive(:ask_responsibles)
    job.perform
  end

  it "sends email to all responsibles" do
    r1 = Fabricate(Group::BottomLayer::Leader.name, group: groups(:bottom_layer_two)).person
    r2 = Fabricate(Group::BottomLayer::LocalGuide.name, group: groups(:bottom_layer_two)).person
    Fabricate(Group::BottomLayer::LocalGuide.name, group: groups(:bottom_layer_two), person: r1)

    mail = double("mail")
    expect(mail).to receive(:deliver_now)
    expect(Person::AddRequestMailer).to receive(:ask_responsibles).with(request, [r1, r2]).and_return(mail)
    job.perform
  end

  it "sends email to last resposibles if person has no roles" do
    person.roles.first.update!(created_at: 1.year.ago)
    person.roles.first.destroy!
    r1 = Fabricate(Group::BottomLayer::Leader.name, group: groups(:bottom_layer_two)).person
    r2 = Fabricate(Group::BottomLayer::LocalGuide.name, group: groups(:bottom_layer_two)).person
    Fabricate(Group::BottomLayer::LocalGuide.name, group: groups(:bottom_layer_two), person: r1)

    mail = double("mail")
    expect(mail).to receive(:deliver_now)
    expect(Person::AddRequestMailer).to receive(:ask_responsibles).with(request, [r1, r2]).and_return(mail)
    job.perform
  end
end
