# frozen_string_literal: true

#  Copyright (c) 2026, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Export::Pdf::Participation do
  let(:participation) { event_participations(:top) }

  it "builds the participant's ability once for all sections" do
    expect(Ability).to receive(:new).with(participation.person).once.and_call_original

    described_class.render(participation)
  end

  it "renders with the given ability" do
    ability = Ability.new(people(:top_leader))
    expect(Ability).not_to receive(:new)

    described_class.render(participation, ability)
  end
end
