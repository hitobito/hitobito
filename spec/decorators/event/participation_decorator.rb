#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Event::ParticipationDecorator, :draper_with_helpers do
  include Rails.application.routes.url_helpers

  let(:person) { people(:top_leader) }
  let(:event) { events(:top_event) }
  let(:participation) { Fabricate(:event_participation, event: event, person: person) }

  subject(:decorator) { described_class.new(participation) }

  describe '#labeled_link' do
    subject(:labeled_link) { decorator.labeled_link }

    it "returns event name as link to particpation" do
      is_expected.to have_text(event.name)
      is_expected.to include(group_event_participation_path(event.groups.first, event, participation))
    end
  end
end
