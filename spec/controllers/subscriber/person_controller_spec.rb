# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Subscriber::PersonController do

  before { sign_in(person) }

  let(:group) { groups(:top_group) }
  let(:person) { people(:top_leader) }
  let(:list) { Fabricate(:mailing_list, group: group) }

  context "POST create" do
    it "without subscriber_id replaces error" do
      post :create, group_id: group.id,
                    mailing_list_id: list.id

      should render_template('crud/new')
      assigns(:subscription).errors.should have(1).item
      assigns(:subscription).errors[:base].should eq ["Person muss ausgewählt werden"]
    end

    it "duplicated subscription replaces error" do
      Fabricate(:subscription, mailing_list: list, subscriber: person)

      expect { post :create, group_id: group.id, mailing_list_id: list.id,
               subscription: { subscriber_id: person.id } }.not_to change(Subscription, :count)

      should render_template('crud/new')
      assigns(:subscription).errors.should have(1).item
      assigns(:subscription).errors[:base].should eq ["Person wurde bereits hinzugefügt"]
    end

    it "updates exclude flag for existing subscription" do
      subscription = Fabricate(:subscription, mailing_list: list, subscriber: person, excluded: true)

      expect { post :create, group_id: group.id, mailing_list_id: list.id,
               subscription: { subscriber_id: person.id } }.not_to change(Subscription, :count)

      subscription.reload.should_not be_excluded
    end

  end
end
