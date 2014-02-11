# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe SubscriptionsController do

  before { sign_in(people(:top_leader)) }

  let(:group) { groups(:top_group) }
  let(:event) { Fabricate(:event, groups: [group]) }
  let(:mailing_list) { Fabricate(:mailing_list, group: group) }

  context 'GET index' do
    it 'groups subscriptions by type' do
      create_group_subscription(mailing_list)
      create_person_subscription(mailing_list)
      create_event_subscription(mailing_list)
      create_person_subscription(mailing_list, true)

      get :index, group_id: group.id, mailing_list_id: mailing_list.id

      assigns(:group_subs).count.should eq 1
      assigns(:person_subs).count.should eq 1
      assigns(:event_subs).count.should eq 1
      assigns(:excluded_person_subs).count.should eq 1
    end

    it 'renders csv' do
      create_group_subscription(mailing_list)
      create_person_subscription(mailing_list)
      create_event_subscription(mailing_list)
      create_person_subscription(mailing_list, true)

      get :index, group_id: group.id, mailing_list_id: mailing_list.id, format: :csv

      lines = response.body.split("\n")
      lines.should have(2).items
      lines[0].should =~ /Vorname;Nachname;.*/
    end
  end

  def create_group_subscription(mailing_list)
    group = Group.all.sample
    Fabricate(:subscription,
              mailing_list: mailing_list,
              subscriber: group,
              related_role_types: [RelatedRoleType.new(role_type: group.role_types.sample.sti_name)]
              )
  end

  def create_person_subscription(mailing_list, excluded = false)
    Fabricate(:subscription, mailing_list: mailing_list, excluded: excluded)
  end

  def create_event_subscription(mailing_list)
    event = Event.all.sample
    Fabricate(:subscription, mailing_list: mailing_list, subscriber: event)
  end

end
