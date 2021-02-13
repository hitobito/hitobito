# encoding: utf-8

#  Copyright (c) 2012-2015, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Person::AddRequestAbility do
  subject { ability }

  let(:ability) { Ability.new(role.person.reload) }

  context :layer_and_below_full do
    let(:role) { Fabricate(Group::TopGroup::Leader.name, group: groups(:top_group)) }

    it "allowed with person in same layer" do
      other = Fabricate(Group::TopGroup::Member.name, group: groups(:top_group)).person
      request = create_request(other)

      is_expected.to be_able_to(:approve, request)
      is_expected.to be_able_to(:reject, request)
      is_expected.to be_able_to(:add_without_request, request)
      is_expected.to be_able_to(:index_person_add_requests, groups(:top_layer))
    end

    it "allowed with person in below layer" do
      other = Fabricate(Group::BottomLayer::Member.name, group: groups(:bottom_layer_one)).person
      request = create_request(other)

      is_expected.to be_able_to(:approve, request)
      is_expected.to be_able_to(:reject, request)
      is_expected.to be_able_to(:add_without_request, request)
      is_expected.to be_able_to(:index_person_add_requests, groups(:bottom_layer_one))
    end

    it "not allowed with non-visible person in below layer" do
      other = Fabricate(Group::BottomGroup::Member.name, group: groups(:bottom_group_one_one)).person
      request = create_request(other)

      is_expected.not_to be_able_to(:approve, request)
      is_expected.not_to be_able_to(:reject, request)
      is_expected.to be_able_to(:add_without_request, request)
    end

    it "allowed with person deleted in below layer" do
      other = Fabricate(Group::BottomLayer::Member.name, group: groups(:bottom_layer_one), created_at: 1.year.ago, deleted_at: 1.month.ago).person
      request = create_request(other)

      is_expected.to be_able_to(:approve, request)
      is_expected.to be_able_to(:reject, request)
      is_expected.to be_able_to(:add_without_request, request)
      is_expected.to be_able_to(:index_person_add_requests, groups(:bottom_layer_one))
    end

    context "in below layer" do
      let(:role) { Fabricate(Group::BottomLayer::Leader.name, group: groups(:bottom_layer_one)) }

      it "allowed with person in same layer" do
        other = Fabricate(Group::BottomGroup::Member.name, group: groups(:bottom_group_one_one)).person
        request = create_request(other)

        is_expected.to be_able_to(:approve, request)
        is_expected.to be_able_to(:reject, request)
        is_expected.to be_able_to(:add_without_request, request)
        is_expected.to be_able_to(:index_person_add_requests, groups(:bottom_layer_one))
      end

      it "allowed with person deleted in same layer" do
        other = Fabricate(Group::BottomGroup::Member.name, group: groups(:bottom_group_one_one)).person
        other.roles.first.update!(created_at: 1.year.ago, deleted_at: 1.month.ago)
        request = create_request(other)

        is_expected.to be_able_to(:approve, request)
        is_expected.to be_able_to(:reject, request)
        is_expected.to be_able_to(:add_without_request, request)
      end

      it "not allowed with person in neighbour layer" do
        other = Fabricate(Group::BottomLayer::Member.name, group: groups(:bottom_layer_two)).person
        request = create_request(other)

        is_expected.not_to be_able_to(:approve, request)
        is_expected.not_to be_able_to(:reject, request)
        is_expected.not_to be_able_to(:add_without_request, request)
        is_expected.not_to be_able_to(:index_person_add_requests, groups(:bottom_layer_two))
      end

      it "not allowed with person in neighbour layer and deleted role in same layer" do
        other = Fabricate(Group::BottomLayer::Member.name, group: groups(:bottom_layer_two)).person
        Fabricate(Group::BottomGroup::Member.name,
          group: groups(:bottom_group_one_one),
          person: other,
          created_at: 1.year.ago,
          deleted_at: 1.month.ago)
        request = create_request(other)

        is_expected.not_to be_able_to(:approve, request)
        is_expected.not_to be_able_to(:reject, request)
        is_expected.not_to be_able_to(:add_without_request, request)
        is_expected.not_to be_able_to(:index_person_add_requests, groups(:bottom_layer_two))
      end

      it "allowed with person in neighbour layer with contact data" do
        other = Fabricate(Group::BottomLayer::Leader.name, group: groups(:bottom_layer_two)).person
        request = create_request(other)

        is_expected.not_to be_able_to(:approve, request)
        is_expected.not_to be_able_to(:reject, request)
        is_expected.to be_able_to(:add_without_request, request)
      end

      it "allowed with person in neighbour layer where user has a simple role" do
        Fabricate(Group::BottomLayer::Member.name, group: groups(:bottom_layer_two), person: role.person)
        other = Fabricate(Group::BottomLayer::Leader.name, group: groups(:bottom_layer_two)).person
        request = create_request(other)

        is_expected.not_to be_able_to(:approve, request)
        is_expected.not_to be_able_to(:reject, request)
        is_expected.to be_able_to(:add_without_request, request)
        is_expected.not_to be_able_to(:index_person_add_requests, groups(:bottom_layer_two))
      end

      it "not allowed with deleted person in neighbour layer where user has a simple role" do
        Fabricate(Group::BottomLayer::Member.name, group: groups(:bottom_layer_two), person: role.person)
        other = Fabricate(Group::BottomLayer::Leader.name, group: groups(:bottom_layer_two), created_at: 1.year.ago).person
        other.roles.first.destroy!

        request = create_request(other)

        is_expected.not_to be_able_to(:approve, request)
        is_expected.not_to be_able_to(:reject, request)
        is_expected.not_to be_able_to(:add_without_request, request)
      end
    end
  end

  context :layer_full do
    let(:role) { Fabricate(Group::TopGroup::LocalGuide.name, group: groups(:top_group)) }

    it "allowed with person in same layer" do
      other = Fabricate(Group::TopLayer::TopAdmin.name, group: groups(:top_layer)).person
      request = create_request(other)

      is_expected.to be_able_to(:approve, request)
      is_expected.to be_able_to(:reject, request)
      is_expected.to be_able_to(:add_without_request, request)
      is_expected.to be_able_to(:index_person_add_requests, groups(:top_layer))
    end

    it "not allowed with person in below layer" do
      other = Fabricate(Group::BottomLayer::Member.name, group: groups(:bottom_layer_one)).person
      request = create_request(other)

      is_expected.not_to be_able_to(:approve, request)
      is_expected.not_to be_able_to(:reject, request)
      is_expected.not_to be_able_to(:add_without_request, request)
      is_expected.not_to be_able_to(:index_person_add_requests, groups(:bottom_layer_one))
    end

    it "allowed with person deleted in same layer" do
      other = Fabricate(Group::TopLayer::TopAdmin.name, group: groups(:top_layer), created_at: 1.year.ago, deleted_at: 1.month.ago).person
      request = create_request(other)

      is_expected.to be_able_to(:approve, request)
      is_expected.to be_able_to(:reject, request)
      is_expected.to be_able_to(:add_without_request, request)
      is_expected.to be_able_to(:index_person_add_requests, groups(:top_layer))
    end
  end

  context :group_full do
    context "with layer and below read" do
      let(:role) { Fabricate(Group::TopGroup::Secretary.name, group: groups(:top_group)) }

      it "allowed with person in same group" do
        other = Fabricate(Group::TopGroup::Member.name, group: groups(:top_group)).person
        request = create_request(other)

        is_expected.to be_able_to(:approve, request)
        is_expected.to be_able_to(:reject, request)
        is_expected.to be_able_to(:add_without_request, request)
        is_expected.not_to be_able_to(:index_person_add_requests, groups(:top_group))
      end

      it "allowed with person deleted in same group" do
        other = Fabricate(Group::TopGroup::Member.name, group: groups(:top_group), created_at: 1.year.ago, deleted_at: 1.month.ago).person
        request = create_request(other)

        is_expected.to be_able_to(:approve, request)
        is_expected.to be_able_to(:reject, request)
        is_expected.to be_able_to(:add_without_request, request)
        is_expected.not_to be_able_to(:index_person_add_requests, groups(:top_group))
      end

      it "not allowed with person in same layer" do
        other = Fabricate(Group::TopLayer::TopAdmin.name, group: groups(:top_layer)).person
        request = create_request(other)

        is_expected.not_to be_able_to(:approve, request)
        is_expected.not_to be_able_to(:reject, request)
        is_expected.to be_able_to(:add_without_request, request)
        is_expected.not_to be_able_to(:index_person_add_requests, groups(:top_layer))
      end

      it "not allowed with person in below layer" do
        other = Fabricate(Group::BottomLayer::Member.name, group: groups(:bottom_layer_one)).person
        request = create_request(other)

        is_expected.not_to be_able_to(:approve, request)
        is_expected.not_to be_able_to(:reject, request)
        is_expected.to be_able_to(:add_without_request, request)
        is_expected.not_to be_able_to(:index_person_add_requests, groups(:bottom_layer_one))
      end

      it "not allowed with non-visible person in below layer" do
        other = Fabricate(Group::BottomGroup::Member.name, group: groups(:bottom_group_one_one)).person
        request = create_request(other)

        is_expected.not_to be_able_to(:approve, request)
        is_expected.not_to be_able_to(:reject, request)
        is_expected.to be_able_to(:add_without_request, request)
      end
    end

    context "with layer and below read" do
      let(:role) { Fabricate(Group::BottomGroup::Leader.name, group: groups(:bottom_group_one_one)) }

      it "allowed with person in same group" do
        other = Fabricate(Group::BottomGroup::Member.name, group: groups(:bottom_group_one_one)).person
        request = create_request(other)

        is_expected.to be_able_to(:approve, request)
        is_expected.to be_able_to(:reject, request)
        is_expected.to be_able_to(:add_without_request, request)
        is_expected.not_to be_able_to(:index_person_add_requests, groups(:bottom_group_one_one))
      end

      it "not allowed with person in same layer" do
        other = Fabricate(Group::BottomGroup::Leader.name, group: groups(:bottom_group_one_two)).person
        request = create_request(other)

        is_expected.not_to be_able_to(:approve, request)
        is_expected.not_to be_able_to(:reject, request)
        is_expected.not_to be_able_to(:add_without_request, request)
        is_expected.not_to be_able_to(:index_person_add_requests, groups(:bottom_layer_one))
      end
    end
  end

  def create_request(person)
    Person::AddRequest::Group.create!(
      person: person,
      requester: people(:bottom_member),
      body: groups(:bottom_layer_one),
      role_type: Group::BottomLayer::Member.sti_name
    )
  end
end
