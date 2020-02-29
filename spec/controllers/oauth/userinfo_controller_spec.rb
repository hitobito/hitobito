# encoding: utf-8

#  Copyright (c) 2012-2019, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.


require 'spec_helper'

describe Doorkeeper::OpenidConnect::UserinfoController do
  let(:user) { people(:top_leader) }
  let(:app) { Oauth::Application.create!(name: 'MyApp', redirect_uri: redirect_uri) }
  let(:redirect_uri) { 'urn:ietf:wg:oauth:2.0:oob' }

  describe 'GET#show' do
    let(:token) { app.access_tokens.create!(resource_owner_id: user.id, scopes: 'openid', expires_in: 2.hours) }

    it 'shows the userinfo' do
      get :show, params: { access_token: token.token }
      expect(response.status).to eq 200
      expect(JSON.parse(response.body)).to eq({ 'sub' => user.id.to_s })
    end

    context 'with name scope' do
      let(:token) { app.access_tokens.create!(resource_owner_id: user.id, scopes: 'openid name', expires_in: 2.hours) }

      before do
        user.update(nickname: 'Filou', address: 'Teststrasse 7', zip_code: '8000', town: 'Zürich', country: 'CH')
      end

      it 'shows the userinfo' do
        get :show, params: { access_token: token.token }
        expect(response.status).to eq 200
        expect(JSON.parse(response.body)).to eq({
          'sub' => user.id.to_s, 'first_name' => user.first_name, 'last_name' => user.last_name, 'nickname' => user.nickname,
          'address' => user.address, 'zip_code' => user.zip_code, 'town' => user.town, 'country' => user.country
        })
      end
    end

    context 'with email scope' do
      let(:token) { app.access_tokens.create!(resource_owner_id: user.id, scopes: 'openid email', expires_in: 2.hours) }

      it 'shows the userinfo' do
        get :show, params: { access_token: token.token }
        expect(response.status).to eq 200
        expect(JSON.parse(response.body)).to eq({ 'sub' => user.id.to_s, 'email' => user.email })
      end
    end
  end
end
