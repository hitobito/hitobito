Airbrake.configure do |config|
  config.api_key     = '0e07cd312b9e0e82056c009921c2585c'
  config.host        = 'errbit.puzzle.ch'
  config.port        = 443
  config.secure      = config.port == 443
  config.ignore         << ActionController::MethodNotAllowed
  config.ignore         << ActionController::RoutingError
  config.ignore         << ActionController::UnknownHttpMethod
  config.params_filters << 'RAILS_DB_PASSWORD'
  config.params_filters << 'RAILS_MAIL_RETRIEVER_PASSWORD'
end