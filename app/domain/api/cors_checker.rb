#  Copyright (c) 2018, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Api::CorsChecker
  attr_reader :request

  def initialize(request)
    @request = request
  end

  def allowed?(source)
    query = Oauth::Application
                .with_api_permission
                .joins(:cors_origins).where(cors_origins: { origin: source })

    query = with_token_condition(query) if oauth_token.present?

    query.exists?
  end

  private

  def oauth_token
    @oauth_token ||= Doorkeeper::OAuth::Token.authenticate(request,
                                                           *Doorkeeper.config.access_token_methods)
  end

  def with_token_condition(query)
    query.joins(:access_tokens).where(oauth_access_tokens: oauth_token)
  end
end
