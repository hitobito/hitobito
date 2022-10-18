# frozen_string_literal: true

#  Copyright (c) 2022, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Healthz::TruemailController do

  describe 'GET show' do

    let(:json) { JSON.parse(response.body) }
    let(:token) { AppStatus.auth_token }

    context 'when true mail can verify valid e-mail address' do
      it 'has HTTP status 200' do
        expect(Truemail).to receive(:valid?).with('hitobito@puzzle.ch').and_return(true)

        get :show, params: { token: token }

        expect(response.status).to eq(200)

        expect(json).to eq('app_status' =>
                           { 'code' => 'ok',
                             'details' => { 'truemail_working' => true,
                                            'verified_email' => 'hitobito@puzzle.ch' } })
      end
    end

    context 'when true mail cannot verify valid e-mail address' do
      it 'has HTTP status 503' do
        expect(Truemail).to receive(:valid?).with('hitobito@puzzle.ch').and_return(false)

        get :show, params: { token: token }

        expect(response.status).to eq(503)

        expect(json).to eq('app_status' =>
                           { 'code' => 'service_unavailable',
                             'details' => { 'truemail_working' => false,
                                            'verified_email' => 'hitobito@puzzle.ch' } })
      end
    end

    context 'auth token' do

      it 'denies access if no auth token given' do
        get :show

        expect(response.status).to eq(401)
      end

      it 'denies access if wrong auth token given' do
        get :show, params: { token: 'wrong token' }

        expect(response.status).to eq(401)
      end

    end
  end
end
