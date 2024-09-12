# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe JsonApi::DocumentationController, type: :controller do
  render_views

  let(:dom) { Capybara::Node::Simple.new(response.body) }

  describe "GET #index" do
    it "renders api documentation mark down" do
      get :index

      expect(response).to have_http_status(:ok)

      expect(dom.all(:css, ".documentation-markdown h2")[0].text).to include "JSON:API"
    end
  end
end
