# frozen_string_literal: true

#  Copyright (c) 2012-2021, Pfadibewegung Schweiz. This file is part of
#  hitobito_cvp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe BlockedController do
  let(:top_leader) { people(:top_leader) }
  before { sign_in(top_leader) }

  render_views

  context 'GET#index' do
    it 'shows blocked text in html' do
      get :index

      expect(response).to have_http_status(403)
      expect(response.body).to have_content(top_leader.full_name)
      expect(response.body).to have_content(I18n.t('blocked.index.explanation'))
    end

    it 'shows blocked text in html' do
      get :index, format: :json

      expect(response).to have_http_status(403)
      expect(JSON.parse(response.body)).to eq({ "error" => "blocked" })
    end
  end
end
