require "spec_helper"

describe JsonApi::EventParticipationAbility do
  let(:participation) { event_participations(:top) }
  let(:group) { participation.groups.first } # top_layer
  let(:event) { participation.event } # top_course
  let(:person) { participation.participant }

  context "person" do
    def accessible_by(person, model_class = Event::Participation)
      person = people(person) unless person.is_a?(Person)
      ability = described_class.new(Ability.new(person))
      model_class.all.accessible_by(ability)
    end

    describe "layer_and_below" do
      it "may read participation" do
        expect(accessible_by(:top_leader)).to eq [participation]
      end

      it "may read participation from group" do
        participation.event.update!(groups: [groups(:bottom_layer_one)])
        expect(accessible_by(:top_leader)).to eq [participation]
      end

      it "may read participation from sub group" do
        sub_group = Fabricate(Group::TopGroup.sti_name, parent: groups(:top_group))
        participation.event.update!(groups: [sub_group])
        expect(accessible_by(:top_leader)).to eq [participation]
      end

      it "may read participation from sub layer" do
        participation.event.update!(groups: [groups(:bottom_layer_one)])
        expect(accessible_by(:top_leader)).to eq [participation]
      end

      it "may not read participation from uppper layer" do
        bottom_layer_leader = Fabricate(Group::BottomLayer::Leader.sti_name, group: groups(:bottom_layer_one)).person
        expect(accessible_by(bottom_layer_leader)).to be_empty
      end
    end

    describe "group_and_below" do
      let!(:person) {
        Fabricate(Group::TopGroup::GroupManager.sti_name, group: groups(:top_group)).person
      }

      it "may not read participation" do
        expect(accessible_by(person)).to be_empty
      end

      it "may read participation from group" do
        participation.event.update!(groups: [groups(:top_group)])
        expect(accessible_by(person)).to eq [participation]
      end

      it "may read participation from sub group" do
        subgroup = Fabricate(Group::TopGroup.sti_name, parent: groups(:top_group))
        participation.event.update!(groups: [subgroup])
        expect(accessible_by(person)).to eq [participation]
      end

      it "may not read participation from sub layer" do
        participation.event.update!(groups: [groups(:bottom_layer_one)])
        expect(accessible_by(person)).to be_empty
      end
    end

    describe "layer" do
      let!(:person) {
        Fabricate(Group::TopGroup::LocalSecretary.sti_name, group: groups(:top_group)).person
      }

      it "may read participation" do
        expect(accessible_by(person)).to eq [participation]
      end

      it "may read group participation" do
        participation.event.update!(groups: [groups(:top_group)])
        expect(accessible_by(person)).to eq [participation]
      end

      it "may read participation from sub group" do
        sub_group = Fabricate(Group::TopGroup.sti_name, parent: groups(:top_group))
        participation.event.update!(groups: [sub_group])
        expect(accessible_by(person)).to eq [participation]
      end

      it "may not read participation from sub layer" do
        participation.event.update!(groups: [groups(:bottom_layer_one)])
        expect(accessible_by(person)).to be_empty
      end

      it "may not read participation from uppper layer" do
        bottom_layer_leader = Fabricate(Group::BottomLayer::Leader.sti_name, group: groups(:bottom_layer_one)).person
        expect(accessible_by(bottom_layer_leader)).to be_empty
      end
    end

    describe "group" do
      let!(:group) { Fabricate(Group::GlobalGroup.sti_name, parent: groups(:top_layer)) }
      let!(:person) { Fabricate(Group::GlobalGroup::Member.sti_name, group:).person }

      around do |example|
        Group::GlobalGroup.event_types = [Event, Event::Course]
        example.run
        Group::GlobalGroup.event_types = []
      end

      it "may not read participation" do
        expect(accessible_by(person)).to be_empty
      end

      it "may read group participation" do
        participation.event.update!(groups: [group])
        expect(accessible_by(person)).to eq [participation]
      end

      it "may not read participation from sub group" do
        sub_group = Fabricate(Group::TopGroup.sti_name, parent: groups(:top_group))
        participation.event.update!(groups: [sub_group])
        expect(accessible_by(person)).to be_empty
      end

      it "may not read participation from sub layer" do
        participation.event.update!(groups: [groups(:bottom_layer_one)])
        expect(accessible_by(person)).to be_empty
      end

      it "may not read participation from uppper layer" do
        bottom_layer_leader = Fabricate(Group::BottomLayer::Leader.sti_name, group: groups(:bottom_layer_one)).person
        expect(accessible_by(bottom_layer_leader)).to be_empty
      end
    end

    describe "guests" do
      it "may read her own guests" do
        other = Fabricate(:event_participation, participant: Fabricate(:event_guest, main_applicant: participation))
        expect(accessible_by(:bottom_member)).to eq [participation, other]
      end

      it "may not read other guests" do
        Fabricate(:event_participation, participant: Fabricate(:event_guest))
        expect(accessible_by(:bottom_member)).to eq [participation]
      end
    end

    describe "people managers" do
      let(:manager) { Fabricate(:person) }

      it "may not read if only managed by other" do
        PeopleManager.create!(manager: people(:top_leader), managed: person)
        expect(accessible_by(manager.reload)).to be_empty
      end

      it "may read if manager" do
        PeopleManager.create!(manager: manager, managed: person)
        expect(accessible_by(manager.reload)).to eq [participation]
      end

      it "may read if manager and managed by other" do
        PeopleManager.create!(manager: manager, managed: person)
        PeopleManager.create!(manager: people(:top_leader), managed: person)
        expect(accessible_by(manager.reload)).to eq [participation]
      end
    end

    describe "roles" do
      context "as participant" do
        before { event_roles(:top_leader).update!(type: "Event::Role::Participant") }

        it "may read her own" do
          expect(accessible_by(:bottom_member)).to eq [participation]
        end

        it "may not read other" do
          Fabricate(:event_participation, event: event)
          expect(accessible_by(:bottom_member)).to eq [participation]
        end

        it "may read other if event allows" do
          other = Fabricate(:event_participation, event: event)
          event.update!(participations_visible: true)
          expect(accessible_by(:bottom_member)).to match_array [participation, other]
        end
      end

      context "as leader" do
        it "may read her own" do
          expect(accessible_by(:bottom_member)).to eq [participation]
        end

        it "may read other" do
          other = Fabricate(:event_participation, event: event)
          expect(accessible_by(:bottom_member)).to match_array [participation, other]
        end

        it "may read other if event allows" do
          other = Fabricate(:event_participation, event: event)
          event.update!(participations_visible: true)
          expect(accessible_by(:bottom_member)).to match_array [participation, other]
        end
      end
    end

    context "not assigned participations" do
      let(:other_person) { Fabricate(:person) }
      let(:application) { Fabricate(:event_application) }
      let!(:other_course) { Fabricate(:course, groups: [groups(:bottom_layer_two)]) }

      let!(:other_participation) {
        Fabricate(:event_participation, event: other_course, application: application)
      }

      it "may read participation from outside of layers if not active " do
        expect(other_participation).not_to be_active
        expect(accessible_by(person)).to match_array [participation, other_participation]
      end

      it "may not read participation from outside of layers if active" do
        other_participation.update!(active: true)
        expect(accessible_by(person)).to match_array [participation]
      end

      it "may not read participation from outside of layers if not in a course offering group" do
        allow(Group).to receive(:course_offerers).and_return(double("relation", pluck: [1, 2, 3]))
        expect(accessible_by(person)).to match_array [participation]
      end

      it "may not read participation from outside of layer if not on waiting lists prios are not set" do
        other_participation.application.update_columns(waiting_list: false, priority_2_id: nil, priority_3_id: nil)
        expect(accessible_by(person)).to match_array [participation]
      end
    end
  end

  context "service token" do
    let(:permitted_top_layer_token) { service_tokens(:permitted_top_layer_token) }

    def accessible_by(token, model_class = Event::Participation)
      token = service_tokens(token) unless token.is_a?(ServiceToken)
      ability = described_class.new(TokenAbility.new(token))
      model_class.all.accessible_by(ability)
    end

    it "includes participation" do
      expect(accessible_by(permitted_top_layer_token)).to eq [participation]
    end

    it "includes participations from sublayer" do
      lower = Fabricate(:event_participation, event: Fabricate(:event, groups: [groups(:bottom_layer_one)]))
      expect(accessible_by(permitted_top_layer_token)).to match_array [participation, lower]
    end

    it "is empty if token may not read participations" do
      permitted_top_layer_token.update!(event_participations: false)
      expect(accessible_by(permitted_top_layer_token)).to be_empty
    end

    it "is empty if token may not read participations for that layer" do
      permitted_top_layer_token.update!(permission: :layer_read)
      event.update!(groups: [groups(:bottom_layer_one)])
      expect(accessible_by(permitted_top_layer_token)).to be_empty
    end
  end

  context "doorkeeper token" do
    let(:application) { Fabricate(:application, scopes: "events") }

    def accessible_by(person)
      token = Fabricate(:access_token, application:, scopes: "events", resource_owner_id: person.id)
      ability = described_class.new(DoorkeeperTokenAbility.new(token))
      Event::Participation.all.accessible_by(ability)
    end

    it "may read participation" do
      expect(accessible_by(person)).to eq [participation]
    end

    it "may not read participation" do
      person = Fabricate(Group::TopGroup::GroupManager.sti_name, group: groups(:top_group)).person
      expect(accessible_by(person)).to be_empty
    end
  end
end
