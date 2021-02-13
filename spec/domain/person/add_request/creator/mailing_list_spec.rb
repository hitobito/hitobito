# encoding: utf-8

#  Copyright (c) 2012-2015, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Person::AddRequest::Creator::MailingList do

  let(:primary_layer) { person.primary_group.layer_group }
  let(:person) { Fabricate(Group::BottomLayer::Member.name, group: groups(:bottom_layer_two)).person }
  let(:requester) { Fabricate(Group::BottomLayer::Leader.name, group: groups(:bottom_layer_one)).person }

  let(:mailing_list) { Fabricate(:mailing_list, group: groups(:bottom_layer_one)) }
  let(:entity) { mailing_list.subscriptions.new(subscriber: person) }

  let(:ability) { Ability.new(requester) }

  subject { Person::AddRequest::Creator::MailingList.new(entity, ability) }

  before { primary_layer.update_column(:require_person_add_requests, true) }

  context "#required" do

    it "is true if primary layer activated requests" do
      expect(subject).to be_required
    end

    it "is true if deleted role already exists" do
      Fabricate(Group::BottomGroup::Member.name, group: groups(:bottom_group_one_one), person: person, deleted_at: 1.year.ago)
      expect(subject).to be_required
    end

    it "is true if person is already excluded from list" do
      mailing_list.subscriptions.create!(subscriber: person, excluded: true)
      expect(subject).to be_required
    end

    it "is false if primary layer deactivated requests" do
      primary_layer.update_column(:require_person_add_requests, false)
      expect(subject).not_to be_required
    end

    it "is false if person has no primary group" do
      person.update_column(:primary_group_id, nil)
      expect(subject).not_to be_required
    end

    it "is false if requester can already show the person" do
      Fabricate(Group::BottomLayer::Member.name, group: groups(:bottom_layer_two), person: requester)
      expect(subject).not_to be_required
    end

    it "is false if person already subscribed to list" do
      mailing_list.subscriptions.create!(subscriber: person)
      expect(subject).not_to be_required
    end

    it "is false if person is supposed to be excluded from list" do
      entity.excluded = true
      expect(subject).not_to be_required
    end

    it "is false if group is added" do
      entity.subscriber = groups(:bottom_group_one_one)
      entity.role_types = [Group::BottomGroup::Leader, Group::BottomGroup::Member].collect(&:sti_name)
      expect(subject).not_to be_required
    end
  end

  context "#create_request" do

    it "creates event request" do
      subject.create_request

      request = subject.request
      expect(request).to be_persisted
      expect(request.body).to eq(mailing_list)
      expect(request.role_type).to be_nil
      expect(request.requester).to eq(requester)
      expect(request.person).to eq(person)
    end

    it "schedules emails" do
      expect do
        subject.create_request
      end.to change { Delayed::Job.count }.by(1)
    end

    it "does not persist if request already exists" do
      Person::AddRequest::MailingList.create!(
        person: person,
        requester: requester,
        body: mailing_list)

      expect do
        subject.create_request
      end.not_to change { Delayed::Job.count }
      expect(subject.request).to be_new_record
      expect(subject.error_message).to match(/Person wurde bereits angefragt/)
    end
  end

end
