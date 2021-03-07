#  Copyright (c) 2021, hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins do |source, env|
      query = Oauth::Application
          .with_api_permission
          .joins(:cors_origins).where(cors_origins: { origin: source })

      query = with_token_condition(query, env)

      query.exists?
    end
    resource '*',
             headers: :any,
             methods: [:get],
             # Allow requests with credentials (specifically the Authorization header)
             credentials: true,
             # Declare to the client that the CORS response may vary depending on these headers
             vary: ['Origin', 'Authorization']
  end
end

def with_token_condition(query, env)
  request = ActionDispatch::Request.new(env)
  token = Doorkeeper::OAuth::Token.authenticate(request, *Doorkeeper.config.access_token_methods)

  return query unless token.present?

  query.joins(:access_tokens).where(oauth_access_tokens: { token: token.token })
end
