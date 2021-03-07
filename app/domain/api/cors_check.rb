#  Copyright (c) 2018, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Api::CorsCheck
  attr_reader :request

  def initialize(request)
    @request = request
  end

  def allowed?(source)
    # In CORS preflight OPTIONS requests, the token headers are not sent along.
    # So this check is as specific as it can be for these cases.
    return false unless cors_origin_allowed?(source)

    if oauth_token.present?
      return false unless oauth_token_allows?(source)
    end

    if service_token.present?
      return false unless service_token_allows?(source)
    end

    true
  end

  private

  def cors_origin_allowed?(source)
    CorsOrigin::where(origin: source).exists?
  end

  def oauth_token_allows?(source)
    oauth_token.application.oauth_token.cors_origins
    Oauth::Application
        .with_api_permission
        .joins(:cors_origins)
        .where(cors_origins: { origin: source })
        .joins(:access_tokens)
        .where(oauth_access_tokens: oauth_token)
        .exists?
  end

  def service_token_allows?(source)
    service_token.cors_origins
        .where(origin: source)
        .exists?
  end

  def oauth_token
    token_authentication.oauth_token
  end

  def service_token
    token_authentication.service_token
  end

  def token_authentication
    @token_authentication ||= Authenticatable::Tokens.new(request, request.params)
  end
end
