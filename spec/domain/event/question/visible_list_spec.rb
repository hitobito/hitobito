# frozen_string_literal: true

#  Copyright (c) 2026, CEVI Regionalverband ZH-SH-GL. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Event::Question::VisibleList do
  let(:event) { Fabricate(:event, groups: [groups(:top_group)]) }
  let(:cook_question) do
    Fabricate(:event_question, event:, question: "Cook question").tap do |q|
      q.update!(visible_role_types: [Event::Role::Cook.sti_name])
    end
  end
  let(:unconfigured_question) do
    Fabricate(:event_question, event:, question: "Unconfigured question")
  end

  before do
    cook_question
    unconfigured_question
  end

  describe "#questions" do
    def questions_seen_by(person, participation = nil)
      described_class.new(event:, ability: Ability.new(person), participation:).questions
    end

    it "returns none of the event's questions without access" do
      expect(questions_seen_by(people(:bottom_member))).to be_empty
    end

    it "returns all of the event's questions" do
      expect(questions_seen_by(people(:top_leader))).to match_array([cook_question, unconfigured_question])
    end

    it "returns only the question configured as visible to that role" do
      participation = Fabricate(:event_participation, event:)
      Fabricate(Event::Role::Cook.sti_name, participation:)
      expect(questions_seen_by(participation.person)).to eq [cook_question]
    end

    context "for a specific participation" do
      let(:participation) { Fabricate(:event_participation, event:) }
      let!(:admin_question) do
        Fabricate(:event_question, event:, admin: true, question: "Admin question")
      end

      it "returns all non-admin questions for participant" do
        questions = questions_seen_by(participation.person, participation)
        expect(questions).to match_array([cook_question, unconfigured_question])
      end

      it "includes the admin question if visible to participants role" do
        admin_question.update!(visible_role_types: [Event::Role::Cook.sti_name])
        Fabricate(Event::Role::Cook.sti_name, participation:)
        expect(questions_seen_by(participation.person, participation)).to include(admin_question)
      end

      it "returns all questions when the viewer has show_full on the participation" do
        Fabricate(Event::Role::Leader.sti_name, participation:)
        questions = questions_seen_by(participation.person, participation)
        expect(questions).to match_array([cook_question, unconfigured_question, admin_question])
      end

      it "returns only visible questions for a role viewing someone else's participation" do
        cook_participation = Fabricate(:event_participation, event:)
        Fabricate(Event::Role::Cook.sti_name, participation: cook_participation)

        questions = questions_seen_by(cook_participation.person, participation)
        expect(questions).to eq [cook_question]
      end
    end

    describe "loading, ordering and chaching" do
      it "orders questions the same way as Event::Question.list" do
        Event::Question.list_alphabetically = true
        list = described_class.new(event:, ability: Ability.new(people(:top_leader)))

        expect(list.questions.map(&:question)).to eq ["Cook question", "Unconfigured question"]
      ensure
        Event::Question.list_alphabetically = false
      end

      it "only queries question_visibilities once, not per question" do
        Fabricate(:event_question, event:, question: "Another cook question")
          .update!(visible_role_types: [Event::Role::Cook.sti_name])

        cook_participation = Fabricate(:event_participation, event:)
        Fabricate(Event::Role::Cook.sti_name, participation: cook_participation)

        expect {
          questions_seen_by(cook_participation.person)
        }.to make.db_queries.with("Event::QuestionVisibility Load" => 1)
      end

      it "reuses shared cache to avoid requerying questions/role_types for another participation" do
        cook_participation = Fabricate(:event_participation, event:)
        Fabricate(Event::Role::Cook.sti_name, participation: cook_participation)

        ability = Ability.new(cook_participation.person)
        cache = {}
        described_class.new(participation: cook_participation, event:, ability:, cache:).questions

        other_participation = Fabricate(:event_participation, event:)
        Fabricate(Event::Role::Cook.sti_name, participation: other_participation)
        list = described_class.new(participation: other_participation, event:, ability:, cache:)

        expect { list.questions }.to make.db_queries.with(
          "Event::Question Load" => 0, "Event::QuestionVisibility Load" => 0
        )
      end

      it "still resolves full_access? independently per participation, even when sharing a cache" do
        admin_question = Fabricate(:event_question, event:, admin: true, question: "Admin question")
        full_access_participation = Fabricate(:event_participation, event:)
        no_access_participation = Fabricate(:event_participation, event:)

        ability = Ability.new(people(:top_leader))

        allow(ability).to receive(:can?).and_wrap_original do |original, permission, subject|
          next false if permission == :show_full && subject == no_access_participation

          original.call(permission, subject)
        end
        cache = {}

        full_list = described_class.new(participation: full_access_participation, event:, ability:, cache:)
        no_access_list = described_class.new(participation: no_access_participation, event:, ability:, cache:)

        expect(full_list.questions).to include(admin_question)
        expect(no_access_list.questions).not_to include(admin_question)
      end
    end
  end

  describe "#answers" do
    let(:participation) { Fabricate(:event_participation, event:) }
    let(:list) do
      described_class.new(
        event:, ability: Ability.new(participation.person), participation: participation
      )
    end

    it "matches answers to the visible, ordered questions" do
      answers = list.answers(participation.answers.to_a)

      expect(answers.map(&:question_id)).to eq [cook_question.id, unconfigured_question.id]
    end

    it "reuses the preloaded question so accessing it does not trigger another query" do
      answers = list.answers(participation.answers.to_a)

      expect(answers.first.question).to equal(list.questions.first)
    end

    it "excludes answers whose question is not visible" do
      cook_participation = Fabricate(:event_participation, event:)
      Fabricate(Event::Role::Cook.sti_name, participation: cook_participation)

      cook_list = described_class.new(ability: Ability.new(cook_participation.person), event:, participation:)
      answers = cook_list.answers(participation.answers.to_a)

      expect(answers.map(&:question_id)).to eq [cook_question.id]
    end
  end
end
