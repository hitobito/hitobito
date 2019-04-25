require 'spec_helper'

describe Oauth::ApplicationsController do
  let(:top_leader) { people(:top_leader) }

  before { sign_in(top_leader) }

  it 'POST#create creates application with custom scopes' do
    post :create, oauth_application: { name: 'MyApp', redirect_uri: 'urn:ietf:wg:oauth:2.0:oob', scopes: %w(name email) }
    application = Oauth::Application.find_by(name: 'MyApp')
    expect(application.scopes).to eq %w(name email)
  end

end
