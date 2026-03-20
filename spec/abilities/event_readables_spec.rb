# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

require "spec_helper"

describe EventReadables do
  let(:user) { role.person.reload }
  let(:ability) { EventReadables.new(user) }

  let!(:other_top_group) { Fabricate(Group::TopGroup.sti_name, parent: groups(:top_layer)) }
  let!(:other_layer) { Fabricate(Group::TopLayer.sti_name) }
  let!(:top_sub_group) { Fabricate(Group::TopGroup.sti_name, parent: groups(:top_group)) }
  let!(:bottom_group) { groups(:bottom_group_one_one) }

  let!(:event_top_layer) { events(:top_event) }
  let!(:event_top_group) { Fabricate(:event, groups: [groups(:top_group)]) }
  let!(:event_top_sub_group) { Fabricate(:event, groups: [top_sub_group]) }
  let!(:event_other_layer) { Fabricate(:event, groups: [other_layer]) }
  let!(:event_bottom_layer) { Fabricate(:event, groups: [groups(:bottom_layer_one)]) }
  let!(:event_bottom_group) { Fabricate(:event, groups: [bottom_group]) }

  subject(:accessible_events) { Event.accessible_by(ability) }

  context :layer_and_below_full do
    let(:role) { Fabricate(Group::TopGroup::Leader.sti_name, group: groups(:top_group)) }

    it "can index events in own group" do
      is_expected.to include(event_top_group)
    end

    it "can index events in sub group" do
      is_expected.to include(event_top_sub_group)
    end

    it "can index events in same layer" do
      is_expected.to include(event_top_layer)
    end

    it "can index events in lower layer" do
      is_expected.to include(event_bottom_layer)
    end

    it "can not index events in other layer" do
      is_expected.not_to include(event_other_layer)
    end
  end

  context :layer_and_below_read do
    let(:role) { Fabricate(Group::TopGroup::Secretary.sti_name, group: groups(:top_group)) }

    it "can index events in own group" do
      is_expected.to include(event_top_group)
    end

    it "can index events in same layer" do
      is_expected.to include(event_top_layer)
    end

    it "can index events in lower layer" do
      is_expected.to include(event_bottom_layer)
    end

    it "can not index events in other layer" do
      is_expected.not_to include(event_other_layer)
    end
  end

  context :layer_full do
    let(:role) { Fabricate(Group::TopGroup::LocalGuide.sti_name, group: groups(:top_group)) }

    it "can index events in own group" do
      is_expected.to include(event_top_group)
    end

    it "can index events in same layer" do
      is_expected.to include(event_top_layer)
    end

    it "can not index events in lower layer" do
      is_expected.not_to include(event_bottom_layer)
    end

    it "can not index events in other layer" do
      is_expected.not_to include(event_other_layer)
    end
  end

  context :layer_read do
    let(:role) { Fabricate(Group::TopGroup::LocalSecretary.sti_name, group: groups(:top_group)) }

    it "can index events in own group" do
      is_expected.to include(event_top_group)
    end

    it "can index events in same layer" do
      is_expected.to include(event_top_layer)
    end

    it "can not index events in lower layer" do
      is_expected.not_to include(event_bottom_layer)
    end

    it "can not index events in other layer" do
      is_expected.not_to include(event_other_layer)
    end
  end

  context :group_and_below_full do
    let(:role) { Fabricate(Group::TopGroup::GroupManager.sti_name, group: groups(:top_group)) }

    it "can index events in own group" do
      is_expected.to include(event_top_group)
    end

    it "can index events in sub group" do
      is_expected.to include(event_top_sub_group)
    end

    it "can index events in same layer" do
      is_expected.to include(event_top_layer)
    end

    it "can not index events in lower layer" do
      is_expected.not_to include(event_bottom_layer)
    end

    it "can not index events in other layer" do
      is_expected.not_to include(event_other_layer)
    end
  end

  context :group_and_below_read do
    let(:role) { Fabricate(Group::TopGroup::Member.sti_name, group: groups(:top_group)) }

    it "can index events in own group" do
      is_expected.to include(event_top_group)
    end

    it "can index events in sub group" do
      is_expected.to include(event_top_sub_group)
    end

    it "can index events in same layer" do
      is_expected.to include(event_top_layer)
    end

    it "can not index events in lower layer" do
      is_expected.not_to include(event_bottom_layer)
    end

    it "can not index events in other layer" do
      is_expected.not_to include(event_other_layer)
    end
  end

  context :group_full do
    let(:role) { Fabricate(Group::BottomGroup::Leader.sti_name, group: bottom_group) }

    it "can index events in own group" do
      is_expected.to include(event_bottom_group)
    end

    it "can index events in same layer" do
      is_expected.to include(event_bottom_layer)
    end

    it "can not index events in above layer" do
      is_expected.not_to include(event_top_layer)
    end

    it "can not index events in other layer" do
      is_expected.not_to include(event_other_layer)
    end
  end

  context :group_read do
    let(:role) { Fabricate(Group::BottomGroup::Member.sti_name, group: bottom_group) }

    it "can index events in own group" do
      is_expected.to include(event_bottom_group)
    end

    it "can index events in same layer" do
      is_expected.to include(event_bottom_layer)
    end

    it "can not index events in above layer" do
      is_expected.not_to include(event_top_layer)
    end

    it "can not index events in other layer" do
      is_expected.not_to include(event_other_layer)
    end
  end

  context :root do
    let(:user) { people(:root) }

    it "can index all groups" do
      is_expected.to match_array Event.all
    end
  end

  context :any do
    let(:user) { people(:bottom_member) }

    it "can index events in own group" do
      is_expected.to include(event_bottom_layer)
    end

    it "can index events in same layer" do
      is_expected.to include(event_bottom_group)
    end

    it "can not index events in above layer" do
      is_expected.not_to include(event_top_layer)
    end

    it "can not index events in other layer" do
      is_expected.not_to include(event_other_layer)
    end

    it "can index globally visible events in other layer" do
      event_other_layer.update(globally_visible: true)
      is_expected.to include(event_other_layer)
    end

    it "can index external application events in other layer" do
      event_other_layer.update(external_applications: true)
      is_expected.to include(event_other_layer)
    end

    it "can index participating events in other layer" do
      Fabricate(:event_participation, event: event_other_layer, participant: user, active: true)
      is_expected.to include(event_other_layer)
    end

    it "cannot index inactive participating events in other layer" do
      Fabricate(:event_participation, event: event_other_layer, participant: user, active: false)
      is_expected.not_to include(event_other_layer)
    end

    it "can index events in other layer with access token" do
      user.shared_access_token = event_other_layer.shared_access_token
      is_expected.to include(event_other_layer)
    end
  end

  context "service token user" do
    let(:token) { Fabricate(:service_token, layer: other_layer, events: true, token: "Secret") }
    let(:user) { token.dynamic_user }

    it "can index events in other layer with service token" do
      is_expected.to include(event_other_layer)
    end
  end
end
