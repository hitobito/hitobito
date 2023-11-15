# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require 'spec_helper'

describe JsonApi::PeopleController, type: [:request] do
  let(:params) { {} }
  let(:top_leader) { people(:top_leader) }
  let(:bottom_member) { people(:bottom_member) }

  describe 'GET #index' do
    context 'unauthorized' do
      it 'returns 401' do
        jsonapi_get '/api/groups', params: params

        expect(response).to have_http_status(401)

        errors = jsonapi_errors

        expect(errors.first.status).to eq('401')

        expect(errors.first.title).to eq('Login benötigt')
        expect(errors.first.detail).to eq('Du must dich einloggen bevor du auf diese Resource zugreifen kannst.')
      end
    end

  end

  context 'authorized' do
    let(:permitted_service_token) { service_tokens(:permitted_top_layer_token) }
    let(:params) { { token: permitted_service_token.token } }
    let(:group) { groups(:bottom_group_two_one) }
    before { group.update!(archived_at: Time.zone.now) }

    it 'GET#index does not include archived group' do
      jsonapi_get '/api/groups', params: params
      expect(response).to have_http_status(200)
      expect(JSON.parse(response.body)['data'].size).to eq Group.count - 1
    end

    it 'GET#index does include archived group with filter with_archived=true' do
      jsonapi_get '/api/groups', params: params.merge(filter: { with_archived: true })
      expect(response).to have_http_status(200)
      expect(JSON.parse(response.body)['data'].size).to eq Group.count
    end

    it 'GET#index does not include archived group with filter with_archived=false' do
      jsonapi_get '/api/groups', params: params.merge(filter: { with_archived: false })
      expect(response).to have_http_status(200)
      expect(JSON.parse(response.body)['data'].size).to eq Group.count - 1
    end

    it 'GET#show does find archived group' do
      groups(:bottom_group_two_one).update!(archived_at: Time.zone.now)
      jsonapi_get "/api/groups/#{group.id}", params: params
      expect(response).to have_http_status(404)
    end
  end
end
