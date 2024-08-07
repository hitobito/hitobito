# frozen_string_literal: true

#  Copyright (c) 2021, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Authenticatable::Tokens
  attr_reader :request, :params

  def initialize(request, params)
    @request = request
    @params = params
  end

  def oauth_token
    @oauth_token ||= extract_doorkeeper_token
  end

  def service_token
    @service_token ||= extract_request_token(:token) do |token|
      token && ServiceToken.find_by(token: token)
    end
  end

  def user_from_token
    @user_from_token ||=
      begin
        email = extract_request_token(:user_email)
        token = extract_request_token(:user_token)
        email && token && Person.find_by(email: email, authentication_token: token)
      end
  end

  private

  def extract_request_token(token)
    x_param = "HTTP_X_#{token.to_s.underscore.upcase}"
    token_value = request.headers[x_param].presence || params[token].presence
    block_given? ? yield(token_value) : token_value
  end

  def extract_doorkeeper_token
    Doorkeeper::OAuth::Token.authenticate(request, *Doorkeeper.config.access_token_methods)
      &.becomes(Oauth::AccessToken)
  end
end
