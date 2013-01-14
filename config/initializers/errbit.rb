Airbrake.configure do |config|
  config.api_key     = '177f24a20b9b72f38e51e40bc9edbf7a'
  config.host        = 'errbit.puzzle.ch'
  config.port        = 443
  config.secure      = config.port == 443
  config.ignore         << ActionController::MethodNotAllowed
  config.ignore         << ActionController::RoutingError
  config.ignore         << ActionController::UnknownHttpMethod
  config.params_filters << 'RAILS_DB_PASSWORD'
  config.params_filters << 'RAILS_MAIL_RETRIEVER_PASSWORD'
end