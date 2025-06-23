#  Copyright (c) 2017, Pfadibewegung Schweiz. This file is part of
#  hitobito_jubla and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_jubla.

require "spec_helper"

describe Event::CancelApplicationJob do
  let(:course) { Fabricate(:course, groups: [groups(:top_layer)], priorization: true) }

  let(:participation) do
    Fabricate(:event_participation, event: course, participant: Fabricate(:person, email: "anybody@example.com"))
  end

  before do
    SeedFu.quiet = true
    SeedFu.seed [Rails.root.join("db", "seeds")]
  end

  subject { described_class.new(course, participation.person) }

  it "sends application cancel email" do
    expect(LocaleSetter).to receive(:with_locale).with(person: participation.person).and_call_original
    subject.perform

    expect(ActionMailer::Base.deliveries.size).to eq(1)
    expect(last_email.subject).to eq("Bestätigung der Abmeldung")
  end
end
