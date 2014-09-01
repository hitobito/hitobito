# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe EventAbility do

  let(:user)    { role.person }
  let(:group)   { role.group }
  let(:event)   { Fabricate(:event, groups: [group]) }

  let(:participant) { Fabricate(Group::BottomGroup::Leader.name.to_sym, group: groups(:bottom_group_one_one)).person }
  let(:participation) { Fabricate(:event_participation, person: participant, event: event, application: Fabricate(:event_application)) }


  subject { Ability.new(user.reload) }

  context :layer_full do
    let(:role) { Fabricate(Group::TopGroup::Leader.name.to_sym, group: groups(:top_group)) }

    context Event do
      it 'may create event in his group' do
        should be_able_to(:create, group.events.new.tap { |e| e.groups << group })
      end

      it 'may create event in his layer' do
        should be_able_to(:create, groups(:toppers).events.new.tap { |e| e.groups << group })
      end

      it 'may update event in his layer' do
        should be_able_to(:update, event)
      end

      it 'may index people for event in his layer' do
        should be_able_to(:index_participations, event)
      end

      it 'may update event in lower layer' do
        other = Fabricate(:event, groups: [groups(:bottom_layer_one)])
        should be_able_to(:update, other)
      end

      it 'may index people for event in lower layer' do
        other = Fabricate(:event, groups: [groups(:bottom_layer_one)])
        should be_able_to(:index_participations, other)
      end

      context 'in other layer' do
        let(:role) { Fabricate(Group::BottomLayer::Leader.name.to_sym, group: groups(:bottom_layer_one)) }

        it 'may not update event' do
          other = Fabricate(:event, groups: [groups(:bottom_layer_two)])
          should_not be_able_to(:update, other)
        end

        it 'may not index people for event' do
          other = Fabricate(:event, groups: [groups(:bottom_layer_two)])
          should_not be_able_to(:index_participations, other)
        end
      end
    end


    context Event::Participation do
      before { Fabricate(Event::Role::Participant.name.to_sym, participation: participation) }

      it 'may show participation' do
        should be_able_to(:show, participation)
      end

      it 'may create participation' do
        should be_able_to(:create, participation)
      end

      it 'may update participation' do
        should be_able_to(:update, participation)
      end

      it 'may destroy participation' do
        should be_able_to(:destroy, participation)
      end

      it 'may show participation in event from lower layer' do
        other = Fabricate(:event_participation, event: Fabricate(:event, groups: [groups(:bottom_group_one_two)]))
        should be_able_to(:show, other)
      end

      it 'may still create when application is not possible' do
        event.stub(application_possible?: false)
        should be_able_to(:create, participation)
      end

      context 'in other layer' do
        let(:role) { Fabricate(Group::BottomLayer::Leader.name.to_sym, group: groups(:bottom_layer_one)) }

        it 'may not show participation in event' do
          other = Fabricate(:event_participation, event: Fabricate(:event, groups: [groups(:bottom_layer_two)]))
          should_not be_able_to(:show, other)
        end
      end
    end

  end

  context :group_full do
    let(:role) { Fabricate(Group::BottomGroup::Leader.name.to_sym, group: groups(:bottom_group_one_one)) }

    context Event do
      it 'may create event in his group' do
        should be_able_to(:create, group.events.new.tap { |e| e.groups << group })
      end

      it 'may update event in his group' do
        should be_able_to(:update, event)
      end

      it 'may destroy event in his group' do
        should be_able_to(:destroy, event)
      end

      it 'may index people for event in his layer' do
        should be_able_to(:index_participations, event)
      end

      it 'may not update event in other group' do
        other = Fabricate(:event, groups: [groups(:bottom_group_one_two)])
        should_not be_able_to(:update, other)
      end

      it 'may not index people for event in other group' do
        other = Fabricate(:event, groups: [groups(:bottom_group_one_two)])
        should_not be_able_to(:index_participations, other)
      end
    end

    context Event::Participation do
      before { Fabricate(Event::Role::Participant.name.to_sym, participation: participation) }

      it 'may show participation' do
        should be_able_to(:show, participation)
      end

      it 'may create participation' do
        should be_able_to(:create, participation)
      end

      it 'may update participation' do
        should be_able_to(:update, participation)
      end

      it 'may destroy participation' do
        should be_able_to(:destroy, participation)
      end

      it 'may not show participation in event from other group' do
        other = Fabricate(:event_participation, event: Fabricate(:event, groups: [groups(:bottom_group_one_two)]))
        should_not be_able_to(:show, other)
      end
    end

  end

  context :event_full do
    let(:group)  { groups(:bottom_layer_one) }
    let(:role)   { Fabricate(Group::BottomLayer::Member.name.to_sym, group: groups(:bottom_layer_one)) }
    let(:participation) { Fabricate(:event_participation, event: event, person: user) }

    before { Fabricate(Event::Role::Leader.name.to_sym, participation: participation) }

    context Event do
      it 'may not create events' do
        should_not be_able_to(:create, group.events.new.tap { |e| e.groups << group })
      end

      it 'may update his event' do
        should be_able_to(:update, event)
      end

      it 'may not destroy his event' do
        should_not be_able_to(:destroy, event)
      end

      it 'may index people his event' do
        should be_able_to(:index_participations, event)
      end

      it 'may not update other event' do
        other = Fabricate(:event, groups: [group])
        should_not be_able_to(:update, other)
      end

      it 'may not index people for other event' do
        other = Fabricate(:event, groups: [group])
        should_not be_able_to(:index_participations, other)
      end

      context 'AssistantLeader' do
        before { Fabricate(Event::Role::AssistantLeader.name.to_sym, participation: participation) }

        it 'may not update event' do
          should be_able_to(:update, event)
        end
      end
    end

    context Event::Participation do
      let(:other) { Fabricate(:event_participation, event: event) }
      before { Fabricate(Event::Role::Participant.name.to_sym, participation: other) }

      it 'may show participation' do
        should be_able_to(:show, other)
      end

      it 'may not create participation' do
        should_not be_able_to(:create, other)
      end

      it 'may update participation' do
        should be_able_to(:update, other)
      end

      it 'may not destroy participation' do
        should_not be_able_to(:destroy, other)
      end

      it 'may not show participation in other event' do
        other = Fabricate(:event_participation, event: Fabricate(:event, groups: [group]))
        should_not be_able_to(:show, other)
      end

      it 'may not update participation in other event' do
        other = Fabricate(:event_participation, event: Fabricate(:event, groups: [group]))
        should_not be_able_to(:update, other)
      end
    end

  end

  context :event_contact_data do
    let(:role)   { Fabricate(Group::BottomGroup::Leader.name.to_sym, group: groups(:bottom_group_one_one)) }
    let(:event)  { Fabricate(:event, groups: [groups(:bottom_layer_one)]) }
    let(:participation) { Fabricate(:event_participation, event: event, person: user) }

    before { Fabricate(Event::Role::Cook.name.to_sym, participation: participation) }

    context Event do
      it 'may show his event' do
        should be_able_to(:show, event)
      end

      it 'may not create events' do
        should_not be_able_to(:create, groups(:bottom_layer_one).events.new.tap { |e| e.groups << groups(:bottom_layer_one) })
      end

      it 'may not update his event' do
        should_not be_able_to(:update, event)
      end

      it 'may not destroy his event' do
        should_not be_able_to(:destroy, event)
      end

      it 'may index people for his event' do
        should be_able_to(:index_participations, event)
      end

      it 'may show other event' do
        other = Fabricate(:event, groups: [groups(:bottom_layer_one)])
        should be_able_to(:show, other)
      end

      it 'may not update other event' do
        other = Fabricate(:event, groups: [groups(:bottom_layer_one)])
        should_not be_able_to(:update, other)
      end

      it 'may not index people for other event' do
        other = Fabricate(:event, groups: [groups(:bottom_layer_one)])
        should_not be_able_to(:index_participations, other)
      end

    end

    context Event::Participation do
      it 'may show his participation' do
        should be_able_to(:show, participation)
      end

      it 'may show other participation' do
        other = Fabricate(:event_participation, event: event)
        Fabricate(Event::Role::Participant.name.to_sym, participation: other)
        should be_able_to(:show, other)
      end

      it 'may not show details of other participation' do
        other = Fabricate(:event_participation, event: event)
        Fabricate(Event::Role::Participant.name.to_sym, participation: other)
        should_not be_able_to(:show_details, other)
      end

      it 'may not show participation in other event' do
        other = Fabricate(:event_participation, event: Fabricate(:event, groups: [groups(:bottom_layer_one)]))
        Fabricate(Event::Role::Participant.name.to_sym, participation: other)
        should_not be_able_to(:show, other)
      end

      it 'may not update his participation' do
        should_not be_able_to(:update, participation)
      end

      it 'may not update other participation' do
        other = Fabricate(:event_participation, event: event)
        Fabricate(Event::Role::Participant.name.to_sym, participation: other)
        should_not be_able_to(:update, other)
      end
    end

  end

  context :in_same_hierarchy do
    let(:role) { Fabricate(Group::BottomLayer::Member.name.to_sym, group: groups(:bottom_layer_one)) }
    let(:participation) { Fabricate(:event_participation, person: user, event: event) }

    context Event::Participation do
      it 'may create his participation' do
        p = event.participations.new
        p.person_id = user.id
        should be_able_to(:create, p)
      end

      it 'may show his participation' do
        should be_able_to(:show, participation)
      end

      it 'may not update his participation' do
        should_not be_able_to(:update, participation)
      end
    end
  end

  context :in_other_hierarchy do
    let(:role)  { Fabricate(Group::BottomLayer::Member.name.to_sym, group: groups(:bottom_layer_two)) }
    let(:event) { Fabricate(:event, groups: [groups(:bottom_layer_one)]) }
    let(:participation) { Fabricate(:event_participation, person: user, event: event) }

    context Event::Participation do
      it 'may create his participation' do
        participation.event.stub(application_possible?: true)
        should be_able_to(:create, participation)
      end

      it 'may not create his participation if application is not possible' do
        participation.event.stub(application_possible?: false)
        should_not be_able_to(:create, participation)
      end

      it 'may show his participation' do
        should be_able_to(:show, participation)
      end

      it 'may not update his participation' do
        should_not be_able_to(:update, participation)
      end
    end

  end

  context :admin do
    let(:role) { Fabricate(Group::TopGroup::Leader.name.to_sym, group: groups(:top_group)) }

    it 'may manage event kinds' do
      should be_able_to(:manage, Event::Kind)
    end
  end

  context :approver do
    let(:event) { Fabricate(:course, groups: [groups(:top_layer)]) }
    let(:role) { Fabricate(Group::BottomLayer::Leader.name.to_sym, group: groups(:bottom_layer_one)) }

    context 'for his guides' do
      it 'may show participations' do
        should be_able_to(:show, participation)
      end

      it 'may show application' do
        should be_able_to(:show, participation.application)
      end

      it 'may approve participations' do
        should be_able_to(:approve, participation.application)
    end
    end

    context 'for other participants' do
      let(:participant) { Fabricate(Group::BottomLayer::Member.name.to_sym, group: groups(:bottom_layer_two)).person }

      # possible to show it because user has :layer_full on course group
      #it 'may not show participations' do
      #  should_not be_able_to(:show, participation)
      #end

      it 'may not show application' do
        should_not be_able_to(:show, participation.application)
      end

      it 'may not approve participations' do
        should_not be_able_to(:approve, participation.application)
      end
    end
  end

  context :application_market do
    let(:course) { Fabricate(:course, groups: [groups(:top_layer)]) }

    let(:role) { Fabricate(Group::TopGroup::Leader.name.to_sym, group: groups(:top_group)) }

    it 'allowed ' do
      should be_able_to(:application_market, course)
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
      should be_able_to(:qualify, course)
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
      should_not be_able_to(:create, group.events.new.tap { |e| e.groups << group })
    end
  end

end
