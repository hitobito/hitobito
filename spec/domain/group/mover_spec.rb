# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'
describe Group::Mover do

  let(:move) { Group::Mover.new(group) }

  describe '#candidates' do
    subject { Group::Mover.new(group) }

    context 'top_group' do
      let(:group) { groups(:top_group) }
      its(:candidates) { should be_blank }
    end

    context 'bottom_layer_one' do
      let(:group) { groups(:bottom_layer_one) }
      its(:candidates) { should be_blank }
    end

    context 'bottom_layer_two' do
      let(:group) { groups(:bottom_layer_two) }
      its(:candidates) { should be_blank }
    end

    context 'bottom_group_one_one' do
      let(:group) { groups(:bottom_group_one_one) }
      its(:candidates) { should =~ groups_for(:bottom_layer_two, :bottom_group_one_two) }
    end

    context 'bottom_group_one_two' do
      let(:group) { groups(:bottom_group_one_two) }
      its(:candidates) { should =~ groups_for(:bottom_layer_two, :bottom_group_one_one) }
    end

    context 'bottom_group_two_one' do
      let(:group) { groups(:bottom_group_two_one) }
      its(:candidates) { should =~ groups_for(:bottom_layer_one) }
    end

    context 'bottom_group_one_one_one' do
      let(:group) { groups(:bottom_group_one_one_one) }
      its(:candidates) { should =~ groups_for(:bottom_layer_one, :bottom_layer_two, :bottom_group_one_two) }
    end

    def groups_for(*args)
      args.map { |arg| groups(arg) }
    end
  end

  context '#perform' do
    let(:group) { groups(:bottom_group_one_one) }
    let(:target) { groups(:bottom_layer_two) }

    context 'moved group' do
      subject { group.reload }
      before { move.perform(target); }

      its(:parent) { should eq target }
      its(:layer_group_id) { should eq target.id }

      it 'nested set should still be valid' do
        Group.should be_valid
      end
    end

    context 'association count' do
      before do
        event = Fabricate(:event, groups: [group])
        Fabricate(:event_participation, event: event)
        Fabricate(Group::BottomGroup::Member.name.to_s, group: group)
      end

      [Group, Role, Person, Event, Event::Participation].each do |model|
        it "does not change #{model} count" do
          expect { move.perform(target) }.not_to change(model, :count)
        end
      end
    end
  end

end
