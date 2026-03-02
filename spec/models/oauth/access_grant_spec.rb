# frozen_string_literal: true

# == Schema Information
#
# Table name: oauth_access_grants
#
#  id                    :integer          not null, primary key
#  resource_owner_id     :integer          not null
#  application_id        :integer          not null
#  token                 :string           not null
#  expires_in            :integer          not null
#  redirect_uri          :text             not null
#  created_at            :datetime         not null
#  revoked_at            :datetime
#  scopes                :string
#  code_challenge        :string
#  code_challenge_method :string
#
# Indexes
#
#  index_oauth_access_grants_on_token  (token) UNIQUE
#

require "spec_helper"

describe Oauth::AccessGrant do
  let(:top_leader) { people(:top_leader) }
  let(:redirect_uri) { "urn:ietf:wg:oauth:2.0:oob" }
  let(:application) { Oauth::Application.create!(name: "MyApp", redirect_uri: redirect_uri) }

  it ".not_expired returns models where created_at + expires_in is less than current_time" do
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
