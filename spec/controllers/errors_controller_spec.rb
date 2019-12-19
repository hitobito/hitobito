#  Copyright (c) 2012-2019, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe ErrorsController do

  render_views

  %w(404 500 503).each do |code|
    it "renders #{code} with correct view and status code" do
      get :show, params: { code: code }
      expect(response).to render_template(code)
      expect(response.status).to eq code.to_i
    end

  end
end
