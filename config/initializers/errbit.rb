# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

if ENV['RAILS_AIRBRAKE_HOST'] && ENV['RAILS_AIRBRAKE_API_KEY']
  Airbrake.configure do |config|
    config.environment = Rails.env
    config.ignore_environments = [:development, :test]
    # if no host is given, ignore all environments
    config.ignore_environments << :production if ENV['RAILS_AIRBRAKE_HOST'].blank?

    config.project_id     = 1
    config.project_key    = ENV['RAILS_AIRBRAKE_API_KEY']
    config.host           = ENV['RAILS_AIRBRAKE_HOST']
    config.port           = (ENV['RAILS_AIRBRAKE_PORT'] || 443).to_i
    config.secure         = config.port == 443
    config.ignore         << ActionController::MethodNotAllowed
    config.ignore         << ActionController::RoutingError
    config.ignore         << ActionController::UnknownHttpMethod
    config.params_filters << 'RAILS_DB_PASSWORD'
    config.params_filters << 'RAILS_MAIL_RETRIEVER_PASSWORD'
    config.params_filters << 'RAILS_AIRBRAKE_API_KEY'
    config.params_filters << 'RAILS_SECRET_TOKEN'
    config.params_filters << 'RAILS_MAIL_RETRIEVER_CONFIG'
    config.params_filters << 'RAILS_MAIL_DELIVERY_CONFIG'
  end
end
