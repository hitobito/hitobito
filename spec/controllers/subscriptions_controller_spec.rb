# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe SubscriptionsController do

  before { sign_in(user) }

  let(:user)  { people(:top_leader) }
  let(:group) { groups(:top_layer) }
  let(:event) { Fabricate(:event, groups: [group], dates: [Fabricate(:event_date, start_at: Time.zone.today)]) }
  let(:mailing_list) { Fabricate(:mailing_list, group: group) }

  context 'GET index' do
    before do
      create_group_subscription(mailing_list)
      @person_subscription = create_person_subscription(mailing_list)
      create_event_subscription(mailing_list)
      @excluded_person_subscription = create_person_subscription(mailing_list, true)
    end

    it 'groups subscriptions by type' do
      get :index, group_id: group.id, mailing_list_id: mailing_list.id

      expect(assigns(:group_subs).count).to eq 1
      expect(assigns(:person_subs).count).to eq 1
      expect(assigns(:event_subs).count).to eq 1
      expect(assigns(:excluded_person_subs).count).to eq 1
      expect(assigns(:person_add_requests)).to eq([])
    end

    it 'renders csv' do
      get :index, group_id: group.id, mailing_list_id: mailing_list.id, format: :csv
      lines = response.body.split("\n")
      expect(lines.size).to eq(3)
      expect(lines[0]).to match(/Vorname;Nachname;.*/)
    end

    it 'renders email addresses with additional ones' do
      e1 = Fabricate(:additional_email, contactable: @person_subscription.subscriber, mailings: true)
      Fabricate(:additional_email, contactable: @excluded_person_subscription.subscriber, mailings: true)
      get :index, group_id: group.id, mailing_list_id: mailing_list.id, format: :email
      expect(@response.body.split(',')).to match_array([people(:bottom_member).email, @person_subscription.subscriber.email, e1.email])
    end

    it 'loads pending person add requests' do
      r1 = Person::AddRequest::MailingList.create!(
              person: Fabricate(:person),
              requester: Fabricate(:person),
              body: mailing_list)

      get :index, group_id: group.id, mailing_list_id: mailing_list.id

      expect(assigns(:person_add_requests)).to eq([r1])
    end
  end

  def create_group_subscription(mailing_list)
    group = groups(:bottom_layer_one)
    Fabricate(:subscription,
              mailing_list: mailing_list,
              subscriber: group,
              related_role_types: [RelatedRoleType.new(role_type: Group::BottomLayer::Member.sti_name)])
  end

  def create_person_subscription(mailing_list, excluded = false)
    Fabricate(:subscription, mailing_list: mailing_list, excluded: excluded)
  end

  def create_event_subscription(mailing_list)
    Fabricate(:subscription, mailing_list: mailing_list, subscriber: event)
  end

end
