require "spec_helper"

describe Oauth::AccessGrant do
  let(:top_leader)   { people(:top_leader) }
  let(:redirect_uri) { "urn:ietf:wg:oauth:2.0:oob" }
  let(:application) { Oauth::Application.create!(name: "MyApp", redirect_uri: redirect_uri) }

  it ".not_expired returns models where created_at + expires_in is less than current_time ", :mysql do
    grant = application.access_grants.create!(resource_owner_id: top_leader.id,
                                              expires_in: 600,
                                              redirect_uri: redirect_uri)
    expect(Oauth::AccessGrant.not_expired).to have(1).item

    grant.update(created_at: 11.minutes.ago)
    expect(Oauth::AccessGrant.not_expired).to be_empty

    grant.update(created_at: 5.minutes.ago)
    expect(Oauth::AccessGrant.not_expired).to have(1).item
  end
end
