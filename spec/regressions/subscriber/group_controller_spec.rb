# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Subscriber::GroupController, type: :controller do
  class << self
    def it_should_redirect_to_show
      it { is_expected.to redirect_to group_mailing_list_subscriptions_path(group, list) }
    end
  end

  let(:list) { mailing_lists(:leaders) }
  let(:group) { list.group }

  let(:test_entry) { subscriptions(:leaders_group) }
  let(:test_entry_attrs) do
    {subscriber_id: groups(:bottom_layer_one).id,
     role_types: ["Group::BottomLayer::Member", "Group::BottomGroup::Leader"]}
  end

  before { sign_in(people(:top_leader)) }

  include_examples "crud controller", skip: [%w(index), %w(show), %w(edit), %w(update), %w(destroy)]

  def deep_attributes(*args)
    {subscriber_id: groups(:bottom_layer_one).id,
     role_types: ["Group::BottomLayer::Member", "Group::BottomGroup::Leader"]}
  end
end
