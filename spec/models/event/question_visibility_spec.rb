# frozen_string_literal: true

#  Copyright (c) 2026, CEVI Regionalverband ZH-SH-GL. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Event::QuestionVisibility do
  let(:question) { events(:top_course).questions.first }

  subject(:visibility) { described_class.new(question: question) }

  it "is valid for a staff Event::Role type" do
    visibility.role_type = Event::Role::Cook.sti_name

    expect(visibility).to be_valid
  end

  it "is invalid for roles with the participations_full permission, as they are implicitly always visible" do
    visibility.role_type = Event::Role::Leader.sti_name
    expect(visibility).not_to be_valid

    visibility.role_type = Event::Role::AssistantLeader.sti_name
    expect(visibility).not_to be_valid
  end

  it "is invalid for an unknown role type" do
    visibility.role_type = "Event::Role::DoesNotExist"

    expect(visibility).not_to be_valid
  end

  describe ".selectable_role_types_for" do
    it "falls back to the base Event role types when no event is given" do
      role_types = described_class.selectable_role_types_for(event: nil, admin: false)

      expect(role_types).to eq described_class.selectable_role_types_for(event: Event, admin: false)
    end
  end
end
