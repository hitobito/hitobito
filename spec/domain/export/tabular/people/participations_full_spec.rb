#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Export::Tabular::People::ParticipationsFull do
  let(:person) { people(:top_leader) }
  let(:participation) { Fabricate(:event_participation, participant: person, event: events(:top_course)) }
  let(:scope) { Event::Participation.where(id: participation.id) }
  let(:people_list) { Export::Tabular::People::ParticipationsFull.new(scope) }

  subject { people_list.attribute_labels }

  context "additional_information" do
    its([:additional_information]) { should eq "Zusätzliche Angaben" }
  end

  context "participation_additional_information" do
    its([:participation_additional_information]) { should eq "Bemerkungen" }
  end

  context "questions" do
    let(:participation) { Fabricate(:event_participation, participant: person, event: events(:top_course)) }
    let(:question) { events(:top_course).questions.first }
    let(:people_list) { Export::Tabular::People::ParticipationsFull.new(scope, Ability.new(person)) }

    before { participation.init_answers }

    it "has keys and values" do
      expect(subject[:"question_#{event_questions(:top_ov).id}"]).to eq "GA oder Halbtax?"
      expect(subject.keys.count { |key| key =~ /question/ }).to eq(3)
    end
  end

  context "answer visibility" do
    let(:event) { Fabricate(:event, groups: [groups(:top_group)]) }
    let(:participation) { Fabricate(:event_participation, participant: person, event: event) }
    let(:question) { Fabricate(:event_question, event: event) }
    let(:viewer) { Fabricate(:person) }
    let(:ability) { Ability.new(viewer) }
    let(:people_list) { Export::Tabular::People::ParticipationsFull.new(scope, ability) }

    before do
      question
      participation
    end

    it "excludes the question column when the viewer has no matching role" do
      allow(viewer).to receive(:event_role_types_for).with(event).and_return([Event::Role::Cook])

      expect(subject.keys).not_to include(:"question_#{question.id}")
    end

    it "includes the question column when the viewer has a matching role" do
      question.visible_role_types = [Event::Role::Cook.sti_name]
      question.save!
      allow(viewer).to receive(:event_role_types_for).with(event).and_return([Event::Role::Cook])

      expect(subject.keys).to include(:"question_#{question.id}")
    end

    it "includes the question column for Event::Role::Leader" do
      allow(viewer).to receive(:event_role_types_for).with(event).and_return([Event::Role::Leader])

      expect(subject.keys).to include(:"question_#{question.id}")
    end

    it "includes the question column for a viewer with full access via other means (e.g. group admin)" do
      allow(viewer).to receive(:event_role_types_for).with(event).and_return([])
      allow(ability).to receive(:can?).with(:index_full_participations, event).and_return(true)

      expect(subject.keys).to include(:"question_#{question.id}")
    end
  end
end
