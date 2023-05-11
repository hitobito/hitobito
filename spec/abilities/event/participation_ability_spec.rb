# frozen_string_literal: true

#  Copyright (c) 2023, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Event::ParticipationAbility do

  let(:user) { role.person }
  subject { Ability.new(user) }

  context 'creating participation for herself' do
    let(:participation) { Event::Participation.new(event: course, person: user) }
    let(:role) { Fabricate(Group::BottomLayer::Leader.name, group: groups(:bottom_layer_one)) }

    context 'in event which can be shown' do
      let(:course) { Event::Course.new(groups: [groups(:bottom_layer_one)], globally_visible: false) }

      it 'may create participation for herself' do
        is_expected.to be_able_to(:create, participation)
      end
    end

    context 'in globally visible event' do
      let(:course) { Event::Course.new(groups: [groups(:bottom_layer_two)], globally_visible: true) }

      it 'may create participation for herself' do
        is_expected.to be_able_to(:create, participation)
      end
    end

    context 'in event which cannot be shown' do
      let(:course) { Event::Course.new(groups: [groups(:bottom_layer_two)], globally_visible: false) }

      it 'may not create participation for herself' do
        is_expected.not_to be_able_to(:create, participation)
      end
    end
  end
end
