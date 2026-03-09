# frozen_string_literal: true

#  Copyright (c) 2026, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Event::Participations::LogController do
  let(:person) { people(:top_leader) }
  let(:participation) { event_participations(:top) }
  let(:event) { participation.event }

  describe "GET index", versioning: true do
    before do
      sign_in(person)

      # create some versions
      participation.update!(additional_information: "something funny about me is that I am not funny")
      participation.roles.first.update!(label: "some new role label")
    end

    it "fetches papertrail versions of event" do
      get :index, params: {group_id: event.groups.first.id, event_id: event.id, id: participation.id}

      versions = assigns(:versions)

      expect(versions.size).to eq(2)
    end
  end
end
