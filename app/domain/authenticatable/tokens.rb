#  Copyright (c) 2018, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Authenticatable::Tokens
  attr_reader :request, :params

  def initialize(request, params)
    @request = request
    @params = params
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
          Person.find_by(email: email, authentication_token: token)
        end
  end

  private

  def extract_request_token(token)
    x_param = "HTTP_X_#{token.to_s.upcase}"
    token_value = params[token].presence || request.headers[x_param].presence
    return token_value unless block_given?
    yield token_value
  end

end
