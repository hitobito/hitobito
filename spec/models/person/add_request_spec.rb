# encoding: utf-8

#  Copyright (c) 2012-2015, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# == Schema Information
#
# Table name: person_add_requests
#
#  id           :integer          not null, primary key
#  person_id    :integer          not null
#  requester_id :integer          not null
#  type         :string           not null
#  body_id      :integer          not null
#  role_type    :string
#  created_at   :datetime         not null
#

require 'spec_helper'

describe Person::AddRequest do

  context '#for_layer' do

    it 'contains people with this primary group layer' do
      admin = Fabricate(Group::TopLayer::TopAdmin.name, group: groups(:top_layer)).person
      topper = Fabricate(Group::TopGroup::Member.name, group: groups(:top_group)).person
      bottom = Fabricate(Group::BottomLayer::Leader.name, group: groups(:bottom_layer_one)).person
      # second role in layer
      Fabricate(Group::TopGroup::Member.name, group: groups(:top_group), person: bottom)
      [admin, topper, bottom].each do |p|
        Person::AddRequest::Group.create!(
          person: p,
          requester: bottom,
          body: groups(:bottom_layer_one),
          role_type: Group::BottomLayer::Member.sti_name)
      end

      people = Person::AddRequest.for_layer(groups(:top_layer)).pluck(:person_id)

      expect(people).to match_array([admin, topper].collect(&:id))
    end

    it 'contains deleted people' do
      admin = Fabricate(Group::TopLayer::TopAdmin.name, group: groups(:top_layer)).person
      ex_topper = Fabricate(Group::TopGroup::Member.name, group: groups(:top_group), created_at: 1.year.ago).person
      ex_topper.roles.first.destroy
      bottom = Fabricate(Group::BottomLayer::Leader.name, group: groups(:bottom_layer_one)).person
      # deleted role in layer
      del = Fabricate(Group::TopGroup::Member.name, group: groups(:top_group), person: bottom, created_at: 1.year.ago)
      del.destroy
      [admin, ex_topper, bottom].each do |p|
        Person::AddRequest::Group.create!(
          person: p,
          requester: bottom,
          body: groups(:bottom_layer_one),
          role_type: Group::BottomLayer::Member.sti_name)
      end

      people = Person::AddRequest.for_layer(groups(:top_layer)).pluck(:person_id)

      expect(people).to match_array([admin, ex_topper].collect(&:id))
    end

  end

  context 'uniqueness' do
    it 'allows multiple requests for the same person in different bodies' do
      Person::AddRequest::Group.create!(
        person: people(:bottom_member),
        requester: people(:top_leader),
        body: groups(:top_layer),
        role_type: Group::TopLayer::TopAdmin.sti_name)

      other = Person::AddRequest::Event.new(
        person: people(:bottom_member),
        requester: people(:top_leader),
        body: events(:top_event),
        role_type: Event::Role::Leader.sti_name)
      expect(other).to be_valid
    end

    it 'does not allow multiple requests for the same person in the same body' do
      Person::AddRequest::Group.create!(
        person: people(:bottom_member),
        requester: people(:top_leader),
        body: groups(:top_group),
        role_type: Group::TopGroup::Leader.sti_name)

      other = Person::AddRequest::Group.new(
        person: people(:bottom_member),
        requester: people(:top_leader),
        body: groups(:top_group),
        role_type: Group::TopGroup::Member.sti_name)
      expect(other).not_to be_valid
    end
  end

  context 'subclasses' do
    let(:group) { groups(:top_group) }
    let(:event) { Fabricate(:event, groups: [group]) }
    let(:abo) { Fabricate(:mailing_list, group: group) }

    before do
      @rg = Person::AddRequest::Group.create!(
        person: people(:bottom_member),
        requester: people(:top_leader),
        body: group,
        role_type: Group::TopGroup::Leader.sti_name)

      @re = Person::AddRequest::Event.create!(
        person: people(:bottom_member),
        requester: people(:top_leader),
        body: event,
        role_type: Event::Role::Leader.sti_name)

      @rm = Person::AddRequest::MailingList.create!(
        person: people(:bottom_member),
        requester: people(:top_leader),
        body: abo)
    end

    context 'group' do
      it '#person_add_requests contains only respective requests' do
        expect(group.person_add_requests).to match_array([@rg])
      end

      it '#body is group' do
        expect(@rg.body).to eq(group)
      end

      it '#to_s contains group type' do
        expect(@rg.to_s).to eq("Top Group TopGroup")
      end

      it '#last_layer_group contains last layer' do
        topper = Fabricate(Group::TopGroup::Member.name, group: groups(:top_group), created_at: 1.year.ago).person
        bottom = Fabricate(Group::BottomLayer::Leader.name, group: groups(:bottom_layer_one)).person
        # second role in layer
        Fabricate(Group::TopGroup::Member.name, group: groups(:top_group), person: bottom)
        Person::AddRequest::Group.create!(
          person: topper,
          requester: bottom,
          body: groups(:bottom_layer_one),
          role_type: Group::BottomLayer::Member.sti_name)
        topper.roles.first.destroy!
        add_request = Person::AddRequest.where(person_id: topper.id)
        expect(add_request.first.send(:last_layer_group)).to eq(groups(:top_layer))
      end
    end

    context 'event' do
      it '#person_add_requests contains only respective requests' do
        expect(event.person_add_requests).to match_array([@re])
      end

      it '#body is event' do
        expect(@re.body).to eq(event)
      end

      it '#to_s contains group type' do
        expect(@re.to_s).to eq("Anlass Eventus in Top Group TopGroup")
      end
    end

    context 'mailing_list' do
      it '#person_add_requests contains only respective requests' do
        expect(abo.person_add_requests).to match_array([@rm])
      end

      it '#body is mailing_list' do
        expect(@rm.body).to eq(abo)
      end

      it '#to_s contains group type' do
        expect(@rm.to_s).to eq("Abo #{abo.to_s} in Top Group TopGroup")
      end
    end

  end
end
