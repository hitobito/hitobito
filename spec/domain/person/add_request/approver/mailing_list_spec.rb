#  Copyright (c) 2012-2015, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Person::AddRequest::Approver::MailingList do
  let(:person) { Fabricate(Group::BottomLayer::Member.name, group: groups(:bottom_layer_two)).person }
  let(:requester) { Fabricate(Group::BottomLayer::Leader.name, group: groups(:bottom_layer_one)).person }

  let(:user) { Fabricate(Group::BottomLayer::Leader.name, group: groups(:bottom_layer_two)).person }

  subject { Person::AddRequest::Approver.for(request, user) }

  let(:group) { groups(:bottom_group_one_one) }
  let(:list) { Fabricate(:mailing_list, group: group) }

  let(:request) do
    Person::AddRequest::MailingList.create!(
      person: person,
      requester: requester,
      body: list
    )
  end

  it "resolves correct subclass based on request" do
    is_expected.to be_a(Person::AddRequest::Approver::MailingList)
  end

  context "#approve" do
    # load before to get correct change counts
    before { subject }

    it "creates a new subscription" do
      expect {
        expect(subject.approve).to eq(true)
      }.to change { Subscription.count }.by(1)

      s = list.subscriptions.first
      expect(s.subscriber).to eq(person)
    end

    it "does nothing if subscription already exists" do
      list.subscriptions.create!(subscriber: person)

      expect {
        expect(subject.approve).to eq(true)
      }.not_to change { Subscription.count }
    end

    it "creates new one if subscription was excluded before" do
      list.subscriptions.create!(subscriber: person, excluded: true)

      expect {
        expect(subject.approve).to eq(true)
      }.not_to change { Subscription.count }

      s = list.subscriptions.first
      expect(s.subscriber).to eq(person)
      expect(s.excluded).to eq(false)
    end
  end
end
