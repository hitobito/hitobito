#  Copyright (c) 2021, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  require_dependency 'api/cors_check'

  allow do
    origins do |origin, env|
      Api::CorsCheck.new(ActionDispatch::Request.new(env)).allowed?(origin)
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
