require "spec_helper"

describe Oauth::ActiveAuthorizationsController do
  let(:top_leader)   { people(:top_leader) }
  let(:redirect_uri) { "urn:ietf:wg:oauth:2.0:oob" }
  let(:application) { Oauth::Application.create!(name: "MyApp", redirect_uri: redirect_uri) }

  before { sign_in(top_leader) }

  def create_grant(attrs = {})
    application.access_grants.create!(attrs.reverse_merge(resource_owner_id: top_leader.id,
                                                          expires_in: 600,
                                                          redirect_uri: redirect_uri))
  end

  context "GET#index", :mysql do
    it "list contains app if active access_grant exists" do
      create_grant
      get :index
      expect(assigns(:entries)).to have(1).item
    end

    it "list contains app if active access_token exists" do
      application.access_tokens.create!(resource_owner_id: top_leader.id)
      get :index
      expect(assigns(:entries)).to have(1).item
    end

    it "list is empty with revoked access_grant" do
      create_grant.update(revoked_at: Time.zone.now)
      get :index
      expect(assigns(:entries)).to be_empty
    end

    it "list is empty with revoked access_token" do
      application.access_tokens.create!(resource_owner_id: top_leader.id, revoked_at: Time.zone.now)
      get :index
      expect(assigns(:entries)).to be_empty
    end

    it "list is empty with expired access_grant" do
      create_grant.update(created_at: 15.minutes.ago)
      get :index
      expect(assigns(:entries)).to be_empty
    end

    it "list is empty with without access_grant or access_token" do
      get :index
      expect(assigns(:entries)).to be_empty
    end

  end

  context "GET#index", :mysql do
    render_views
    let(:person) { people(:bottom_member) }

    it "renders destroy link" do
      sign_in(person)
      create_grant(resource_owner_id: person.id)
      get :index
      expect(assigns(:entries)).to have(1).item
      expect(response.body).to match(/fa-trash-alt/)
    end
  end

  context "DELETE#destroy" do
    it "revokes acces_grant and access_token" do
      grant = create_grant
      token = application.access_tokens.create!(resource_owner_id: top_leader.id)
      delete :destroy, params: { id: application.id }
      expect(flash[:notice]).to eq "Zugang zu <i>MyApp</i> wurde annulliert"
      expect(token.reload).to be_revoked
      expect(grant.reload).to be_revoked
      expect(response).to redirect_to oauth_active_authorizations_path
    end
  end
end

