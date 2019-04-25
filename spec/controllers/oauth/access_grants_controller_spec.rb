require 'spec_helper'

describe Oauth::AccessGrantsController do
  let(:top_leader)   { people(:top_leader) }
  let(:redirect_uri) { 'urn:ietf:wg:oauth:2.0:oob' }

  before { sign_in(top_leader) }

  it 'DELETE#destroy destroys grant and redirects to application' do
    application = Oauth::Application.create!(name: 'MyApp', redirect_uri: redirect_uri)
    grant = application.access_grants.create!(resource_owner_id: top_leader.id, expires_in: 10, redirect_uri: redirect_uri)
    expect do
      delete :destroy, id: grant.id
    end.to change { application.access_grants.count }.by(-1)
    expect(response).to redirect_to oauth_application_path(application)
  end

end
