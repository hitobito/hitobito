# frozen_string_literal: true

#  Copyright (c) 2019-2023, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

Doorkeeper::OpenidConnect.configure do
  issuer Settings.oidc.issuer

  # $>openssl genrsa 2048
  #   signing_key <<-EOL
  # -----BEGIN RSA PRIVATE KEY-----
  # ....
  # -----END RSA PRIVATE KEY-----
  # EOL

  signing_key Settings.oidc.signing_key.join.presence

  subject_types_supported [:public]

  resource_owner_from_access_token do |access_token|
    # Example implementation:
    # User.find_by(id: access_token.resource_owner_id)
    Person.find_by(id: access_token.resource_owner_id)
  end

  auth_time_from_resource_owner do |resource_owner|
    # Example implementation:
    # resource_owner.current_sign_in_at
  end

  reauthenticate_resource_owner do |resource_owner, return_to|
    next unless resource_owner.is_a?(Person) # skip if we have no authenticated resource owner

    store_location_for resource_owner, return_to
    sign_out resource_owner
    redirect_to new_person_session_url(oauth: true)
  end

  subject do |resource_owner, application|
    # Example implementation:
    # resource_owner.id
    resource_owner.id

    # or if you need pairwise subject identifier, implement like below:
    # Digest::SHA256.hexdigest("#{resource_owner.id}#{URI.parse(application.redirect_uri).host}#{'your_secret_salt'}")
  end

  end_session_endpoint do
    oidc_logout_url
  end

  # Protocol to use when generating URIs for the discovery endpoint,
  # for example if you also use HTTPS in development
  # protocol do
  #   :https
  # end

  # Expiration time on or after which the ID Token MUST NOT be accepted for processing. (default 120 seconds).
  # expiration 600

  # claims do
  #   normal_claim :_foo_ do |resource_owner|
  #     resource_owner.foo
  #   end

  #   normal_claim :_bar_ do |resource_owner|
  #     resource_owner.bar
  #   end
  # end

  claims do
    # NOTE - We need this block as a placeholder, claims are configured via OidcClaimSetup
  end
end

Rails.application.config.after_initialize do
  OidcClaimSetup.new.run
end

class Doorkeeper::OpenidConnect::ClaimsBuilder
  # Patch the claims generate method, because doorkeeper does not allow to serve the same claim on
  # two different scopes and also ignores its own NormalClaim#name attribute, so we can't have
  # multiple separate claims with different scopes and the same name either.
  def self.generate(access_token, response)
    resource_owner = Doorkeeper::OpenidConnect.configuration.resource_owner_from_access_token.call(access_token)

    Doorkeeper::OpenidConnect.configuration.claims.to_h.map do |name, claim|
      if access_token.scopes.exists?(claim.scope) && claim.response.include?(response)
        # Only change is on the next line: We use claim.name instead of name as key
        [claim.name, claim.generator.call(resource_owner, access_token.scopes, access_token)]
      end
    end.compact.to_h
  end
end

class Doorkeeper::OpenidConnect::UserInfo
  # Patch the claims JSON encode method for the userinfo endpoint, to disable filtering out
  # empty and nil values.
  def as_json(*_)
    claims # .reject { |_, value| value.nil? || value == '' }
  end
end
