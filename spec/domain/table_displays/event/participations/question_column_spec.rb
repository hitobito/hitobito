# frozen_string_literal: true

#  Copyright (c) 2026, CEVI Regionalverband ZH-SH-GL. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe TableDisplays::Event::Participations::QuestionColumn do
  let(:event) { Fabricate(:event, groups: [groups(:top_group)]) }
  let(:cook_question) do
    Fabricate(:event_question, event: event, question: "Cook question").tap do |q|
      q.update!(visible_role_types: [Event::Role::Cook.sti_name])
    end
  end
  let(:unconfigured_question) do
    Fabricate(:event_question, event: event, question: "Unconfigured question")
  end
  let(:attr) { "event_question_#{cook_question.id}" }
  let(:unconfigured_attr) { "event_question_#{unconfigured_question.id}" }

  # the viewer holds a Cook role and browses a table listing OTHER participants' rows -
  # distinct from the viewer's own participation, so the "own participation" bypass in
  # Event::Question::VisibleList does not interfere with these role-based checks
  let(:viewer_participation) { Fabricate(:event_participation, event: event) }
  let(:ability) { Ability.new(viewer_participation.person) }
  let(:column) { described_class.new(ability, model_class: Event::Participation) }

  let(:other_participation) { Fabricate(:event_participation, event: event) }
  let(:another_participation) { Fabricate(:event_participation, event: event) }

  before do
    cook_question
    unconfigured_question
    Fabricate(Event::Role::Cook.sti_name, participation: viewer_participation)
  end

  describe "#allowed?" do
    it "shows a question configured as visible to the viewer's role" do
      allowed = column.send(:allowed?, other_participation, attr, other_participation, attr)

      expect(allowed).to eq true
    end

    it "hides a question not configured as visible to the viewer's role" do
      allowed = column.send(
        :allowed?, other_participation, unconfigured_attr, other_participation, unconfigured_attr
      )

      expect(allowed).to eq false
    end

    it "reuses the event's questions and the viewer's role types across participations of the " \
      "same event (no N+1 across rows of a table render)" do
      column.send(:allowed?, other_participation, attr, other_participation, attr)
      another_participation

      expect {
        column.send(:allowed?, another_participation, attr, another_participation, attr)
      }.to make.db_queries.with("Event::Question Load" => 0, "Event::QuestionVisibility Load" => 0)
    end
  end
end
