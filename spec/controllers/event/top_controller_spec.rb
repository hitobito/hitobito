# frozen_string_literal: true

#  Copyright (c) 2012-2021, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Event::TopController do
  let(:top_leader) { people(:top_leader) }
  let(:event) { events(:top_course) }

  before { sign_in(top_leader) }

  context "GET show" do
    context "html" do
      it "redirects to group event path" do
        get :show, params: {id: event.id}
        is_expected.to redirect_to(group_event_path(event.groups.first, event, format: :html))
      end
    end

    context "json with token" do
      it "forwards token param in redirect" do
        get :show, params: {id: event.id, token: "secret", format: :json}
        is_expected.to redirect_to(group_event_path(event.groups.first, event, format: :json, token: "secret"))
      end
    end
  end
end
