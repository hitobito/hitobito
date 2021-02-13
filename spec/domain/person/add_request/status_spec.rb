# encoding: utf-8

#  Copyright (c) 2012-2015, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Person::AddRequest::Status do

  let(:person) { Fabricate(Group::BottomLayer::Member.name, group: groups(:bottom_layer_two)).person }
  let(:requester) { Fabricate(Group::BottomLayer::Leader.name, group: groups(:bottom_layer_one)).person }
  let(:user) { Fabricate(Group::BottomLayer::Leader.name, group: groups(:bottom_layer_two)).person }

  let(:body_type) { body.class.base_class.name }


  subject { Person::AddRequest::Status.for(person.id, body_type, body.id) }

  context "Group" do

    let(:body) { groups(:bottom_layer_one) }

    it "resolves to correct subclass" do
      expect(subject).to be_a(Person::AddRequest::Status::Group)
    end

    context "#pending?" do
      it "is false if no request exists" do
        expect(subject).not_to be_pending
      end

      it "is true if request exists" do
        Person::AddRequest::Group.create!(
          person: person,
          requester: requester,
          body: body,
          role_type: Group::BottomLayer::Member.sti_name
        )
        expect(subject).to be_pending
      end
    end

    context "#created?" do
      it "is false if no role exists" do
        expect(subject).not_to be_created
      end

      it "is true if role exists" do
        Fabricate(Group::BottomLayer::Leader.name, group: body, person: person)
        expect(subject).to be_created
      end
    end

  end

end
