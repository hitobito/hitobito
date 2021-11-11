# frozen_string_literal: true

#  Copyright (c) 2021, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require_dependency 'cors_origin'

class Api::CorsCheck
  attr_reader :request

  def initialize(request)
    @request = request
  end

  def allowed?(origin)
    if oauth_token_declines?(origin) ||
        service_token_declines?(origin) ||
        no_token_declines?(origin)
      return false
    end

    true
  end

  private

  def no_token_declines?(origin)
    # In CORS preflight OPTIONS requests, the token headers are not sent along.
    # So this check is as specific as it can be for these cases.
    no_token_present? && !::CorsOrigin.where(origin: origin).exists?
  end

  def service_token_declines?(origin)
    service_token.present? && !allows_origin?(service_token, origin)
  end

  def oauth_token_declines?(origin)
    return false if oauth_token.blank?

    !(oauth_token_has_api_access? && allows_origin?(oauth_token.application, origin))
  end

  def oauth_token_has_api_access?
    oauth_token.application.includes_scope?(:api)
  end

  def allows_origin?(auth_method, origin)
    auth_method.cors_origins.where(origin: origin).exists?
  end

  def oauth_token
    token_authentication.oauth_token
  end

  def service_token
    token_authentication.service_token
  end

  def no_token_present?
    [:service_token, :oauth_token].none? { |token| send(token).present? }
  end

  def token_authentication
    @token_authentication ||= Authenticatable::Tokens.new(request, request.params)
  end
end
