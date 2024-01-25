# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require 'spec_helper'

xdescribe MailingLists::Subscribables do
  let(:person) { people(:top_leader) }
  subject(:list) { described_class.new(person).list }

  it 'includes all subscribable lists' do
    expect(list).to have(3).items
  end

  it 'excludes all non subscribable lists' do
    MailingList.update_all(subscribable_for: :anyone)
    expect(list).to be_empty
  end

  context 'with group subscription' do
    let(:top_group) { groups(:top_group) }
    let(:mailing_list) { mailing_lists(:top_group) }
    before { MailingList.update_all(subscribable_for: :anyone) }

    it 'includes list' do
      create_subscription(top_group, person.roles.first.type)
      expect(list).to include(mailing_list)
    end

    context 'with hierarchy specific role' do
      let!(:above) { Fabricate(Group::GlobalGroup.sti_name, parent: groups(:top_layer)) }
      let!(:below) { Fabricate(Group::GlobalGroup.sti_name, parent: groups(:bottom_group_one_one)) }

      let!(:mailing_list) do
        Fabricate(:mailing_list, group: groups(:bottom_layer_one), subscribable_for: :anyone)
      end

      it 'is empty per default' do
        expect(list).to be_empty
      end

      it 'is present when subscription is below' do
        create_global_member_role(below)
        create_subscription(below, Group::GlobalGroup::Member.sti_name)
        expect(list).to eq [mailing_list]
      end

      it 'is blank when subscription with type exists but for above layer' do
        create_global_member_role(above)
        create_subscription(mailing_lists(:leaders), Group::GlobalGroup::Member.sti_name)
        expect(list).to be_empty
      end
    end
  end

  def create_global_member_role(group)
    Fabricate(Group::GlobalGroup::Member.sti_name, person: person, group: group)
  end

  def create_subscription(group, *role_types)
    related_role_types = role_types.collect { |t| RelatedRoleType.new(role_type: t) }
    mailing_list.update(subscribable_for: :anyone)
    mailing_list.subscriptions.create!(subscriber: group, related_role_types: related_role_types)
  end
end
