Airbrake.configure do |config|
  config.api_key     = ENV['RAILS_AIRBRAKE_API_KEY']
  config.host        = ENV['RAILS_AIRBRAKE_HOST']
  config.port        = ENV['RAILS_AIRBRAKE_PORT'] || 443
  config.secure      = config.port == 443
  config.ignore         << ActionController::MethodNotAllowed
  config.ignore         << ActionController::RoutingError
  config.ignore         << ActionController::UnknownHttpMethod
  config.params_filters << 'RAILS_DB_PASSWORD'
  config.params_filters << 'RAILS_MAIL_RETRIEVER_PASSWORD'
  config.params_filters << 'RAILS_AIRBRAKE_API_KEY'
end