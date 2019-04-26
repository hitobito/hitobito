# encoding: utf-8

#  Copyright (c) 2012-2019, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.


require 'spec_helper'

describe Oauth::AccessTokensController do
  let(:top_leader)   { people(:top_leader) }
  let(:redirect_uri) { 'urn:ietf:wg:oauth:2.0:oob' }

  before { sign_in(top_leader) }

  it 'DELETE#destroy destroys token and redirects to application' do
    application = Oauth::Application.create!(name: 'MyApp', redirect_uri: redirect_uri)
    token = application.access_tokens.create!(resource_owner_id: top_leader.id)
    expect do
      delete :destroy, id: token.id
    end.to change { application.access_tokens.count }.by(-1)
    expect(response).to redirect_to oauth_application_path(application)
  end

end
