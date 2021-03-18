# frozen_string_literal: true

#  Copyright (c) 2012-2021, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe EventAbility do
  let(:user)    { role.person }
  let(:group)   { role.group }
  let(:event)   { Fabricate(:event, groups: [group], globally_visible: false) }

  let(:participant) do
    Fabricate(Group::BottomGroup::Leader.name.to_sym,
              group: groups(:bottom_group_one_one)).person
  end
  let(:participation) do
    Fabricate(:event_participation,
              person: participant,
              event: event,
              application: Fabricate(:event_application))
  end

  let(:token) { Devise.friendly_token }

  subject { Ability.new(user.reload) }

  context :layer_and_below_full do
    let(:role) { Fabricate(Group::TopGroup::Leader.name.to_sym, group: groups(:top_group)) }

    context Event do
      it 'may create event in his group' do
        is_expected.to be_able_to(:create, group.events.new.tap { |e| e.groups << group })
      end

      it 'may create event in his layer' do
        is_expected.to be_able_to(:create,
                                  groups(:toppers).events.new.tap { |e| e.groups << group })
      end

      it 'may update event in his layer' do
        is_expected.to be_able_to(:update, event)
      end

      it 'may index people for event in his layer' do
        is_expected.to be_able_to(:index_participations, event)
      end

      it 'may update event in lower layer' do
        other = Fabricate(:event, groups: [groups(:bottom_layer_one)], globally_visible: false)
        is_expected.to be_able_to(:update, other)
      end

      it 'may index people for event in lower layer' do
        other = Fabricate(:event, groups: [groups(:bottom_layer_one)])
        is_expected.to be_able_to(:index_participations, other)
      end

      context 'in other layer' do
        let(:role) do
          Fabricate(Group::BottomLayer::Leader.name.to_sym, group: groups(:bottom_layer_one))
        end

        it 'may not update event' do
          other = Fabricate(:event, groups: [groups(:bottom_layer_two)])
          is_expected.not_to be_able_to(:update, other)
        end

        it 'may not index people for event' do
          other = Fabricate(:event, groups: [groups(:bottom_layer_two)])
          is_expected.not_to be_able_to(:index_participations, other)
        end
      end

      it 'may see lower layers events' do
        other = Fabricate(:event, groups: [groups(:bottom_layer_one)])
        is_expected.to be_able_to(:show, other)
      end

      it 'may not see sibling layers events' do
        sibling_group = Fabricate(Group::TopLayer.name.to_sym, parent: nil, name: 'SecondTop')

        other = Fabricate(:event, groups: [sibling_group], globally_visible: false)
        is_expected.to_not be_able_to(:show, other)
      end

      it 'may see sibling layers events with a token' do
        sibling_group = Fabricate(Group::TopLayer.name.to_sym, parent: nil, name: 'SecondTop')

        other = Fabricate(:event, groups: [sibling_group], globally_visible: false, shared_access_token: token)
        user.shared_access_token = token

        is_expected.to be_able_to(:show, other)
      end

      it 'may see sibling layers globally visible events' do
        sibling_group = Fabricate(Group::TopLayer.name.to_sym, parent: nil, name: 'SecondTop')

        other = Fabricate(:event, groups: [sibling_group], globally_visible: true)
        is_expected.to be_able_to(:show, other)
      end
    end

    context Event::Course do
      it 'may list all courses' do
        is_expected.to be_able_to(:list_all, described_class)
      end

      it 'may export course list' do
        is_expected.to be_able_to(:export_list, described_class)
      end

      it 'may not list all courses if not in course layer' do
        Group::TopLayer.event_types.delete(described_class)
        Group.root_types(Group::TopLayer)
        begin
          is_expected.not_to be_able_to(:list_all, described_class)
        ensure
          Group::TopLayer.event_types << described_class
          Group.root_types(Group::TopLayer)
        end
      end

      it 'may not see sibling layers events' do
        sibling_group = Fabricate(Group::TopLayer.name.to_sym, parent: nil, name: 'SecondTop')

        other = Fabricate(:course, groups: [sibling_group], globally_visible: false)
        is_expected.to_not be_able_to(:show, other)
      end

      it 'may see sibling layers events with a token' do
        sibling_group = Fabricate(Group::TopLayer.name.to_sym, parent: nil, name: 'SecondTop')

        other = Fabricate(:course, groups: [sibling_group], globally_visible: false, shared_access_token: token)
        user.shared_access_token = token

        is_expected.to be_able_to(:show, other)
      end

      it 'may see sibling layers globally visible events' do
        sibling_group = Fabricate(Group::TopLayer.name.to_sym, parent: nil, name: 'SecondTop')

        other = Fabricate(:course, groups: [sibling_group], globally_visible: true)
        is_expected.to be_able_to(:show, other)
      end
    end

    context Event::Participation do
      before { Fabricate(Event::Role::Participant.name.to_sym, participation: participation) }

      it 'may show participation' do
        is_expected.to be_able_to(:show, participation)
      end

      it 'may create participation' do
        is_expected.to be_able_to(:create, participation)
      end

      it 'may update participation' do
        is_expected.to be_able_to(:update, participation)
      end

      it 'may destroy participation' do
        is_expected.to be_able_to(:destroy, participation)
      end

      it 'may show participation in event from lower layer' do
        other = Fabricate(:event_participation,
                          event: Fabricate(:event, groups: [groups(:bottom_group_one_two)]))
        is_expected.to be_able_to(:show, other)
      end

      it 'may still create when application is not possible' do
        allow(event).to receive_messages(application_possible?: false)
        is_expected.to be_able_to(:create, participation)
      end

      context 'in other layer' do
        let(:role) do
          Fabricate(Group::BottomLayer::Leader.name.to_sym, group: groups(:bottom_layer_one))
        end

        it 'may not show participation in event' do
          other = Fabricate(:event_participation,
                            event: Fabricate(:event, groups: [groups(:bottom_layer_two)]))
          is_expected.not_to be_able_to(:show, other)
        end
      end
    end
  end

  context :layer_full do
    let(:role) { Fabricate(Group::TopGroup::LocalGuide.name.to_sym, group: groups(:top_group)) }

    context Event do
      it 'may create event in his group' do
        is_expected.to be_able_to(:create, group.events.new.tap { |e| e.groups << group })
      end

      it 'may create event in his layer' do
        is_expected.to be_able_to(:create,
                                  groups(:toppers).events.new.tap { |e| e.groups << group })
      end

      it 'may update event in his layer' do
        is_expected.to be_able_to(:update, event)
      end

      it 'may index people for event in his layer' do
        is_expected.to be_able_to(:index_participations, event)
      end

      it 'may not update event in lower layer' do
        other = Fabricate(:event, groups: [groups(:bottom_layer_one)])
        is_expected.not_to be_able_to(:update, other)
      end

      it 'may not index people for event in lower layer' do
        other = Fabricate(:event, groups: [groups(:bottom_layer_one)])
        is_expected.not_to be_able_to(:index_participations, other)
      end

      it 'may not see lower layers events' do
        other = Fabricate(:event, groups: [groups(:bottom_group_one_one)], globally_visible: false)
        is_expected.not_to be_able_to(:show, other)
      end

      it 'may see lower layers events with a token' do
        other = Fabricate(:event, groups: [groups(:bottom_group_one_one)], globally_visible: false, shared_access_token: token)
        user.shared_access_token = token
        is_expected.to be_able_to(:show, other)
      end

      it 'may see lower layers globally visible events' do
        other = Fabricate(:event, groups: [groups(:bottom_group_one_one)], globally_visible: true)
        is_expected.to be_able_to(:show, other)
      end

      it 'may not see sibling layers events' do
        other = Fabricate(:event, groups: [groups(:bottom_layer_two)], globally_visible: false)
        is_expected.not_to be_able_to(:show, other)
      end

      it 'may see sibling layers events with a token' do
        other = Fabricate(:event, groups: [groups(:bottom_layer_two)], globally_visible: false, shared_access_token: token)
        user.shared_access_token = token
        is_expected.to be_able_to(:show, other)
      end

      it 'may not see sibling layers globally visible events' do
        other = Fabricate(:event, groups: [groups(:bottom_layer_two)], globally_visible: true)
        is_expected.to be_able_to(:show, other)
      end
    end

    context Event::Course do
      it 'may list all courses' do
        is_expected.to be_able_to(:list_all, Event::Course)
      end

      it 'may not export course list' do
        is_expected.not_to be_able_to(:export_list, Event::Course)
      end

      it 'may not see sibling layers events' do
        other = Fabricate(:course, groups: [groups(:bottom_layer_two)], globally_visible: false)
        is_expected.not_to be_able_to(:show, other)
      end

      it 'may see sibling layers events with a token' do
        other = Fabricate(:course, groups: [groups(:bottom_layer_two)], globally_visible: false, shared_access_token: token)
        user.shared_access_token = token
        is_expected.to be_able_to(:show, other)
      end

      it 'may not see sibling layers globally visible events' do
        other = Fabricate(:course, groups: [groups(:bottom_layer_two)], globally_visible: true)
        is_expected.to be_able_to(:show, other)
      end
    end

    context Event::Participation do
      before { Fabricate(Event::Role::Participant.name.to_sym, participation: participation) }

      it 'may show participation' do
        is_expected.to be_able_to(:show, participation)
      end

      it 'may create participation' do
        is_expected.to be_able_to(:create, participation)
      end

      it 'may update participation' do
        is_expected.to be_able_to(:update, participation)
      end

      it 'may destroy participation' do
        is_expected.to be_able_to(:destroy, participation)
      end

      it 'may not show participation in event from lower layer' do
        other = Fabricate(:event_participation,
                          event: Fabricate(:event, groups: [groups(:bottom_group_one_two)]))
        is_expected.not_to be_able_to(:show, other)
      end

      it 'may show participation on waiting list with prio_1 in event from other layer' do
        event = Fabricate(:event, groups: [groups(:bottom_group_one_two)])
        application = Fabricate(:event_application, priority_1: event, waiting_list: true) # rubocop:disable Naming/VariableNumber
        other = Fabricate(:event_participation,
                          event: event,
                          application: application)
        is_expected.to be_able_to(:show, other)
        is_expected.to be_able_to(:show_priorities, other.application)
      end

      it 'may still create when application is not possible' do
        allow(event).to receive_messages(application_possible?: false)
        is_expected.to be_able_to(:create, participation)
      end

    end

  end

  context :group_and_below_full do
    let(:role) { Fabricate(Group::TopLayer::TopAdmin.name.to_sym, group: groups(:top_layer)) }

    context Event do
      context 'in own group' do
        it 'may create event' do
          is_expected.to be_able_to(:create, group.events.new.tap { |e| e.groups << group })
        end

        it 'may update event' do
          is_expected.to be_able_to(:update, event)
        end

        it 'may destroy event' do
          is_expected.to be_able_to(:destroy, event)
        end

        it 'may index people for event' do
          is_expected.to be_able_to(:index_participations, event)
        end
      end

      context 'in sibling group' do
        let(:sibling_group) { Fabricate(group.type.to_sym, parent: group.parent, name: 'SecondTop') }

        it 'may not see sibling group events' do
          other = Fabricate(:event, groups: [sibling_group], globally_visible: false)
          is_expected.to_not be_able_to(:show, other)
        end

        it 'may see sibling group events with a token' do
          other = Fabricate(:event, groups: [sibling_group], globally_visible: false, shared_access_token: token)
          user.shared_access_token = token
          is_expected.to be_able_to(:show, other)
        end

        it 'may see sibling group globally visible events' do
          other = Fabricate(:event, groups: [sibling_group], globally_visible: true)
          is_expected.to be_able_to(:show, other)
        end
      end

      context 'in below group' do
        let(:group) { groups(:top_group) }

        it 'may create event' do
          is_expected.to be_able_to(:create, group.events.new.tap { |e| e.groups << group })
        end

        it 'may update event' do
          is_expected.to be_able_to(:update, event)
        end

        it 'may destroy event' do
          is_expected.to be_able_to(:destroy, event)
        end

        it 'may index people for event' do
          is_expected.to be_able_to(:index_participations, event)
        end

        it 'may see lower group events' do
          is_expected.to be_able_to(:show, event)
        end
      end

      context 'in below layer' do
        let(:group) { groups(:bottom_layer_one) }

        it 'may not update event' do
          is_expected.not_to be_able_to(:update, event)
        end

        it 'may not index people for event' do
          is_expected.not_to be_able_to(:index_participations, event)
        end

        it 'may not see lower layer events' do
          is_expected.not_to be_able_to(:show, event)
        end

        it 'may see lower layer events with a token' do
          event.shared_access_token = token
          user.shared_access_token = token
          is_expected.to be_able_to(:show, event)
        end

        it 'may see lower layer globally visible events' do
          event.update(globally_visible: true)
          event.reload
          is_expected.to be_able_to(:show, event)
        end
      end
    end

    context Event::Course do
      let(:event)   { Fabricate(:course, groups: [group], globally_visible: false) }

      it 'may not list all courses' do
        is_expected.not_to be_able_to(:list_all, Event::Course)
      end

      context 'in sibling group' do
        let(:sibling_group) { Fabricate(group.type.to_sym, parent: group.parent, name: 'SecondTop') }

        it 'may not see sibling group events' do
          other = Fabricate(:course, groups: [sibling_group], globally_visible: false)
          is_expected.to_not be_able_to(:show, other)
        end

        it 'may see sibling group events with a token' do
          other = Fabricate(:course, groups: [sibling_group], globally_visible: false, shared_access_token: token)
          user.shared_access_token = token
          is_expected.to be_able_to(:show, other)
        end

        it 'may see sibling group globally visible events' do
          other = Fabricate(:course, groups: [sibling_group], globally_visible: true)
          is_expected.to be_able_to(:show, other)
        end
      end

      context 'in below group' do
        let(:group) { groups(:top_group) }

        it 'may see lower group events' do
          is_expected.to be_able_to(:show, event)
        end
      end

      context 'in below layer' do
        let(:group) { groups(:bottom_layer_one) }

        it 'may not see lower layer events' do
          is_expected.not_to be_able_to(:show, event)
        end

        it 'may see lower layer events with a token' do
          event.shared_access_token = token
          user.shared_access_token = token
          is_expected.to be_able_to(:show, event)
        end

        it 'may see lower layer globally visible events' do
          event.update(globally_visible: true)
          event.reload
          is_expected.to be_able_to(:show, event)
        end
      end
    end

    context Event::Participation do
      before { Fabricate(Event::Role::Participant.name.to_sym, participation: participation) }

      context 'in same group' do
        it 'may show participation' do
          is_expected.to be_able_to(:show, participation)
        end

        it 'may create participation' do
          is_expected.to be_able_to(:create, participation)
        end

        it 'may update participation' do
          is_expected.to be_able_to(:update, participation)
        end

        it 'may destroy participation' do
          is_expected.to be_able_to(:destroy, participation)
        end
      end

      context 'in below group' do
        let(:group) { groups(:top_group) }
        it 'may show participation' do
          is_expected.to be_able_to(:show, participation)
        end

        it 'may create participation' do
          is_expected.to be_able_to(:create, participation)
        end

        it 'may update participation' do
          is_expected.to be_able_to(:update, participation)
        end

        it 'may destroy participation' do
          is_expected.to be_able_to(:destroy, participation)
        end
      end

      context 'in below layer' do
        let(:group) { groups(:bottom_layer_one) }

        it 'may not show participation' do
          is_expected.not_to be_able_to(:show, participation)
        end
      end
    end

  end

  context :group_full do
    let(:role) do
      Fabricate(Group::BottomGroup::Leader.name.to_sym, group: groups(:bottom_group_one_one))
    end

    context Event do
      it 'may create event in his group' do
        is_expected.to be_able_to(:create, group.events.new.tap { |e| e.groups << group })
      end

      it 'may update event in his group' do
        is_expected.to be_able_to(:update, event)
      end

      it 'may destroy event in his group' do
        is_expected.to be_able_to(:destroy, event)
      end

      it 'may index people for event in his layer' do
        is_expected.to be_able_to(:index_participations, event)
      end

      it 'may not update event in other group' do
        other = Fabricate(:event, groups: [groups(:bottom_group_one_two)])
        is_expected.not_to be_able_to(:update, other)
      end

      it 'may not index people for event in other group' do
        other = Fabricate(:event, groups: [groups(:bottom_group_one_two)])
        is_expected.not_to be_able_to(:index_participations, other)
      end

      it 'may not see sibling group events' do
        other = Fabricate(:event, groups: [groups(:bottom_group_one_two)], globally_visible: false)
        is_expected.not_to be_able_to(:show, other)
      end

      it 'may see sibling group events with a token' do
        other = Fabricate(:event, groups: [groups(:bottom_group_one_two)], globally_visible: false, shared_access_token: token)
        user.shared_access_token = token
        is_expected.to be_able_to(:show, other)
      end

      it 'may see sibling group globally visible events' do
        other = Fabricate(:event, groups: [groups(:bottom_group_one_two)], globally_visible: true)
        is_expected.to be_able_to(:show, other)
      end

      context 'below layers' do
        let(:role) do
          Fabricate(Group::GlobalGroup::Leader.name.to_sym, group: groups(:toppers))
        end

        it 'may not see lower layers events' do
          other = Fabricate(:event,
                            groups: [groups(:bottom_group_one_one)], globally_visible: false)
          is_expected.to_not be_able_to(:show, other)
        end

        it 'may see lower layers events' do
          other = Fabricate(:event,
                            groups: [groups(:bottom_group_one_one)], globally_visible: false,
                            shared_access_token: token)
          user.shared_access_token = token
          is_expected.to be_able_to(:show, other)
        end

        it 'may see lower layers globally visible events' do
          other = Fabricate(:event, groups: [groups(:bottom_group_one_one)], globally_visible: true)
          is_expected.to be_able_to(:show, other)
        end
      end
    end

    context Event::Course do
      it 'may not list all courses' do
        is_expected.not_to be_able_to(:list_all, Event::Course)
      end

      context 'below layers' do
        let(:role) do
          Fabricate(Group::GlobalGroup::Leader.name.to_sym, group: groups(:toppers))
        end

        it 'may see lower layers globally visible events' do
          other = Fabricate(:event, groups: [groups(:bottom_group_one_one)], globally_visible: true)
          is_expected.to be_able_to(:show, other)
        end
      end
    end

    context Event::Participation do
      before { Fabricate(Event::Role::Participant.name.to_sym, participation: participation) }

      it 'may show participation' do
        is_expected.to be_able_to(:show, participation)
      end

      it 'may create participation' do
        is_expected.to be_able_to(:create, participation)
      end

      it 'may update participation' do
        is_expected.to be_able_to(:update, participation)
      end

      it 'may destroy participation' do
        is_expected.to be_able_to(:destroy, participation)
      end

      it 'may not show participation in event from other group' do
        other = Fabricate(:event_participation,
                          event: Fabricate(:event, groups: [groups(:bottom_group_one_two)]))
        is_expected.not_to be_able_to(:show, other)
      end
    end
  end

  context :group_read do
    let(:role) do
      Fabricate(Group::GlobalGroup::Member.name.to_sym, group: groups(:toppers))
    end

    context Event do
      it 'may not see lower layers events' do
        other = Fabricate(:event, groups: [groups(:bottom_layer_two)], globally_visible: false)
        is_expected.not_to be_able_to(:show, other)
      end

      it 'may not see lower layers events' do
        other = Fabricate(:event, groups: [groups(:bottom_layer_two)], globally_visible: false, shared_access_token: token)
        user.shared_access_token = token
        is_expected.to be_able_to(:show, other)
      end

      it 'may see lower layers globally visible events' do
        other = Fabricate(:event, groups: [groups(:bottom_layer_two)], globally_visible: true)
        is_expected.to be_able_to(:show, other)
      end

      it 'may not see sibling layers events' do
        sibling_group = Fabricate(group.type.to_sym, parent: group.parent, name: 'SecondTopper')
        other = Fabricate(:event, groups: [sibling_group], globally_visible: false)
        is_expected.not_to be_able_to(:show, other)
      end

      it 'may see sibling layers events' do
        sibling_group = Fabricate(group.type.to_sym, parent: group.parent, name: 'SecondTopper')
        other = Fabricate(:event, groups: [sibling_group], globally_visible: false, shared_access_token: token)
        user.shared_access_token = token
        is_expected.to be_able_to(:show, other)
      end

      it 'may see sibling layers globally visible events' do
        sibling_group = Fabricate(group.type.to_sym, parent: group.parent, name: 'SecondTopper')
        other = Fabricate(:event, groups: [sibling_group], globally_visible: true)
        is_expected.to be_able_to(:show, other)
      end
    end

    context Event::Course do
      it 'may not see lower layers events' do
        other = Fabricate(:course, groups: [groups(:bottom_layer_two)], globally_visible: false)
        is_expected.not_to be_able_to(:show, other)
      end

      it 'may not see lower layers events' do
        other = Fabricate(:course, groups: [groups(:bottom_layer_two)], globally_visible: false, shared_access_token: token)
        user.shared_access_token = token
        is_expected.to be_able_to(:show, other)
      end

      it 'may see lower layers globally visible events' do
        other = Fabricate(:course, groups: [groups(:bottom_layer_two)], globally_visible: true)
        is_expected.to be_able_to(:show, other)
      end
    end
  end

  context :event_full do
    let(:group)  { groups(:bottom_layer_one) }
    let(:role)   do
      Fabricate(Group::BottomLayer::Member.name.to_sym, group: groups(:bottom_layer_one))
    end
    let(:participation) { Fabricate(:event_participation, event: event, person: user) }
    let(:event_role) { Fabricate(Event::Role::Leader.name.to_sym, participation: participation) }

    before { event_role }

    context Event do
      it 'may not create events' do
        is_expected.not_to be_able_to(:create, group.events.new.tap { |e| e.groups << group })
      end

      it 'may update his event' do
        is_expected.to be_able_to(:update, event)
      end

      it 'may not destroy his event' do
        is_expected.not_to be_able_to(:destroy, event)
      end

      it 'may index people his event' do
        is_expected.to be_able_to(:index_participations, event)
      end

      it 'may not update other event' do
        other = Fabricate(:event, groups: [group])
        is_expected.not_to be_able_to(:update, other)
      end

      it 'may not index people for other event' do
        other = Fabricate(:event, groups: [group])
        is_expected.not_to be_able_to(:index_participations, other)
      end

      context 'AssistantLeader' do
        before { Fabricate(Event::Role::AssistantLeader.name.to_sym, participation: participation) }

        it 'may not update event' do
          is_expected.to be_able_to(:update, event)
        end
      end
    end

    context Event::Participation do
      let(:other) { Fabricate(:event_participation, event: event) }
      before { Fabricate(Event::Role::Participant.name.to_sym, participation: other) }

      it 'may show participation' do
        is_expected.to be_able_to(:show, other)
      end

      it 'may not create participation' do
        is_expected.not_to be_able_to(:create, other)
      end

      it 'may update participation' do
        is_expected.to be_able_to(:update, other)
      end

      it 'may not destroy participation' do
        is_expected.not_to be_able_to(:destroy, other)
      end

      it 'may not show participation in other event' do
        other = Fabricate(:event_participation, event: Fabricate(:event, groups: [group]))
        is_expected.not_to be_able_to(:show, other)
      end

      it 'may not update participation in other event' do
        other = Fabricate(:event_participation, event: Fabricate(:event, groups: [group]))
        is_expected.not_to be_able_to(:update, other)
      end
    end

    context Event::Role do
      let(:other) { Fabricate(:event_participation, event: event) }
      let(:other_role) { Fabricate(Event::Role::Leader.name.to_sym, participation: other) }
      before { other_role }

      it 'may update own role' do
        is_expected.to be_able_to(:update, event_role)
      end

      it 'may update other role' do
        is_expected.to be_able_to(:update, other_role)
      end

      it 'may not destroy own leader role' do
        is_expected.not_to be_able_to(:destroy, event_role)
      end

      it 'may destroy own helper role' do
        helper = Fabricate(Event::Role::Speaker.name.to_sym,
                           participation: participation)
        is_expected.to be_able_to(:destroy, helper)
      end

      it 'may destroy other role' do
        is_expected.to be_able_to(:destroy, other_role)
      end

      it 'may not update role in other event' do
        other = Fabricate(Event::Role::Participant.name.to_sym,
                          participation: Fabricate(:event_participation,
                                                   event: Fabricate(:event, groups: [group])))
        is_expected.not_to be_able_to(:update, other)
      end
    end

  end

  context :participations_read do
    let(:role) do
      Fabricate(Group::BottomGroup::Leader.name.to_sym, group: groups(:bottom_group_one_one))
    end
    let(:event) { Fabricate(:event, groups: [groups(:bottom_layer_one)]) }
    let(:participation) { Fabricate(:event_participation, event: event, person: user) }
    let(:event_role)    { Event::Role::Cook }

    before { Fabricate(event_role.name.to_sym, participation: participation) }

    context Event do
      it 'may show his event' do
        is_expected.to be_able_to(:show, event)
      end

      it 'may not create events' do
        is_expected.not_to be_able_to(:create,
                                      groups(:bottom_layer_one).events.new.tap do |e|
                                        e.groups << groups(:bottom_layer_one)
                                      end)
      end

      it 'may not update his event' do
        is_expected.not_to be_able_to(:update, event)
      end

      it 'may not destroy his event' do
        is_expected.not_to be_able_to(:destroy, event)
      end

      it 'may index people for his event' do
        is_expected.to be_able_to(:index_participations, event)
      end

      it 'may show other event' do
        other = Fabricate(:event, groups: [groups(:bottom_layer_one)])
        is_expected.to be_able_to(:show, other)
      end

      it 'may not update other event' do
        other = Fabricate(:event, groups: [groups(:bottom_layer_one)])
        is_expected.not_to be_able_to(:update, other)
      end

      it 'may not index people for other event' do
        other = Fabricate(:event, groups: [groups(:bottom_layer_one)])
        is_expected.not_to be_able_to(:index_participations, other)
      end
    end

    context Event::Role::Participant do
      let(:event_role) { Event::Role::Participant }

      before { participation.update(active: true) }

      context Event do
        it 'may index people for his event with visible participations' do
          event.update(participations_visible: true)
          expect(event).to be_participations_visible

          is_expected.to be_able_to(:index_participations, event)
        end

        it 'may not index people for his event with invisible participations' do
          event.update(participations_visible: false)
          expect(event).not_to be_participations_visible

          is_expected.not_to be_able_to(:index_participations, event)
        end
      end

      context Event::Course do
        let(:event) { Fabricate(:course) }

        it 'may index people for his event' do
          is_expected.to be_able_to(:index_participations, event)
        end
      end
    end

    context Event::Participation do
      it 'may show his participation' do
        is_expected.to be_able_to(:show, participation)
      end

      it 'may show other participation' do
        other = Fabricate(:event_participation, event: event)
        Fabricate(Event::Role::Participant.name.to_sym, participation: other)
        is_expected.to be_able_to(:show, other)
      end

      it 'may not show details of other participation' do
        other = Fabricate(:event_participation, event: event)
        Fabricate(Event::Role::Participant.name.to_sym, participation: other)
        is_expected.not_to be_able_to(:show_details, other)
      end

      it 'may not show participation in other event' do
        other = Fabricate(:event_participation,
                          event: Fabricate(:event, groups: [groups(:bottom_layer_one)]))
        Fabricate(Event::Role::Participant.name.to_sym, participation: other)
        is_expected.not_to be_able_to(:show, other)
      end

      it 'may not update his participation' do
        is_expected.not_to be_able_to(:update, participation)
      end

      it 'may not update other participation' do
        other = Fabricate(:event_participation, event: event)
        Fabricate(Event::Role::Participant.name.to_sym, participation: other)
        is_expected.not_to be_able_to(:update, other)
      end
    end

  end

  context 'inactive participation' do
    let(:role) do
      Fabricate(Group::BottomGroup::Leader.name.to_sym, group: groups(:bottom_group_one_one))
    end
    let(:event) { Fabricate(:course, groups: [groups(:bottom_layer_one)]) }
    let(:participation) do
      Fabricate(:event_participation,
                event: event,
                person: user,
                active: false,
                application: Fabricate(:event_application))
    end

    before { Fabricate(Event::Course::Role::Participant.name.to_sym, participation: participation) }

    context Event do
      it 'may show his event' do
        expect(participation).not_to be_active
        is_expected.to be_able_to(:show, event)
      end

      it 'may not update his event' do
        is_expected.not_to be_able_to(:update, event)
      end

      it 'may not index people for his event' do
        is_expected.not_to be_able_to(:index_participations, event)
      end

    end

    context Event::Participation do
      it 'may show his participation' do
        is_expected.to be_able_to(:show, participation)
      end

      it 'may not show other participation' do
        other = Fabricate(:event_participation, event: event)
        Fabricate(Event::Course::Role::Participant.name.to_sym, participation: other)
        is_expected.not_to be_able_to(:show, other)
      end

      it 'may not show details of other participation' do
        other = Fabricate(:event_participation, event: event)
        Fabricate(Event::Course::Role::Participant.name.to_sym, participation: other)
        is_expected.not_to be_able_to(:show_details, other)
      end

      it 'may not show participation in other event' do
        other = Fabricate(:event_participation,
                          event: Fabricate(:event, groups: [groups(:bottom_layer_one)]))
        Fabricate(Event::Course::Role::Participant.name.to_sym, participation: other)
        is_expected.not_to be_able_to(:show, other)
      end

      it 'may not update his participation' do
        is_expected.not_to be_able_to(:update, participation)
      end

      it 'may not update other participation' do
        other = Fabricate(:event_participation, event: event)
        Fabricate(Event::Course::Role::Participant.name.to_sym, participation: other)
        is_expected.not_to be_able_to(:update, other)
      end

      it 'may destroy his participation if applications_cancelable' do
        event.update!(applications_cancelable: true, application_closing_at: Time.zone.today)
        is_expected.to be_able_to(:destroy, participation)
      end

      it 'may not destroy his participation if applications cancelable and applications closed' do
        event.update!(applications_cancelable: true,
                      application_closing_at: Time.zone.today - 1.day)
        is_expected.not_to be_able_to(:destroy, participation)
      end

      it 'may not destroy his participation if applications not cancelable' do
        event.update!(applications_cancelable: false,
                      application_closing_at: Time.zone.today + 10.days)
        is_expected.not_to be_able_to(:destroy, participation)
      end

      it 'may not destroy other participation if applications cancelable' do
        event.update!(applications_cancelable: true, application_closing_at: Time.zone.today)
        other = Fabricate(:event_participation, event: event)
        Fabricate(Event::Course::Role::Participant.name.to_sym, participation: other)
        is_expected.not_to be_able_to(:destroy, other)
      end
    end
  end

  context :in_same_hierarchy do
    let(:role) do
      Fabricate(Group::BottomLayer::Member.name.to_sym, group: groups(:bottom_layer_one))
    end
    let(:participation) { Fabricate(:event_participation, person: user, event: event) }

    context Event::Participation do
      it 'may create his participation' do
        p = event.participations.new
        p.person_id = user.id
        is_expected.to be_able_to(:create, p)
      end

      it 'may show his participation' do
        is_expected.to be_able_to(:show, participation)
      end

      it 'may not update his participation' do
        is_expected.not_to be_able_to(:update, participation)
      end
    end
  end

  context :in_other_hierarchy do
    let(:role) do
      Fabricate(Group::BottomLayer::Member.name.to_sym, group: groups(:bottom_layer_two))
    end
    let(:event) { Fabricate(:event, groups: [groups(:bottom_layer_one)]) }
    let(:participation) { Fabricate(:event_participation, person: user, event: event) }

    context Event::Participation do
      it 'may create his participation' do
        allow(participation.event).to receive_messages(application_possible?: true)
        is_expected.to be_able_to(:create, participation)
      end

      it 'may not create his participation if application is not possible' do
        allow(participation.event).to receive_messages(application_possible?: false)
        is_expected.not_to be_able_to(:create, participation)
      end

      it 'may show his participation' do
        is_expected.to be_able_to(:show, participation)
      end

      it 'may not update his participation' do
        is_expected.not_to be_able_to(:update, participation)
      end
    end

  end

  context :admin do
    let(:role) { Fabricate(Group::TopGroup::Leader.name.to_sym, group: groups(:top_group)) }

    it 'may manage event kinds' do
      is_expected.to be_able_to(:manage, Event::Kind)
    end
  end

  context :approver do
    let(:event) { Fabricate(:course, groups: [groups(:top_layer)]) }
    let(:role) do
      Fabricate(Group::BottomLayer::Leader.name.to_sym, group: groups(:bottom_layer_one))
    end

    context 'for his guides' do
      it 'may show participations' do
        is_expected.to be_able_to(:show, participation)
      end

      it 'may show application' do
        is_expected.to be_able_to(:show_priorities, participation.application)
      end

      it 'may approve participations' do
        is_expected.to be_able_to(:approve, participation.application)
      end
    end

    context 'for other participants' do
      let(:participant) do
        Fabricate(Group::BottomLayer::Member.name.to_sym, group: groups(:bottom_layer_two)).person
      end

      before { participation.application.priority_2 = nil }

      it 'may not show participations' do
        is_expected.not_to be_able_to(:show, participation)
      end

      it 'may not show application' do
        is_expected.not_to be_able_to(:show_priorities, participation.application)
      end

      it 'may not approve participations' do
        is_expected.not_to be_able_to(:approve, participation.application)
      end
    end
  end

  context :application_market do
    let(:course) { Fabricate(:course, groups: [groups(:top_layer)]) }

    let(:role) { Fabricate(Group::TopGroup::Leader.name.to_sym, group: groups(:top_group)) }

    it 'allowed ' do
      is_expected.to be_able_to(:application_market, course)
    end

  end

  context :qualify do
    let(:course) { Fabricate(:course, groups: [groups(:top_layer)]) }

    before do
      participation = Fabricate(:event_participation, event: course, person: user)
      Fabricate(:event_role, participation: participation, type: 'Event::Role::Leader')
    end

    let(:role) { Fabricate(Group::TopGroup::Leader.name.to_sym, group: groups(:top_group)) }

    it 'allowed for course' do
      is_expected.to be_able_to(:qualify, course)
    end
  end

  context 'destroyed group' do
    let(:group) { groups(:bottom_layer_two) }
    let(:role) { Fabricate(Group::BottomLayer::Leader.name.to_sym, group: group) }
    before do
      group.children.each { |g| g.destroy }
      group.destroy
    end

    it 'cannot create new event' do
      is_expected.not_to be_able_to(:create, group.events.new.tap { |e| e.groups << group })
    end
  end

  context 'as person without roles' do
    let(:person_without_roles) { Fabricate(:person, primary_group: groups(:top_layer)) }

    subject { Ability.new(person_without_roles) }

    it 'may show if external applications enabled' do
      is_expected.to be_able_to(:show, events(:top_course))
    end

    it 'may not show if external applications disabled' do
      events(:top_event)[:globally_visible] = false
      is_expected.to_not be_able_to(:show, events(:top_event))
    end

    it 'may not list_available' do
      is_expected.to_not be_able_to(:list_available, Event)
    end
  end
end
