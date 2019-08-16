Raven.configure do |config|
  config.sanitize_fields = Rails.application.config.filter_parameters.map(&:to_s)

  if ENV['OPENSHIFT_BUILD_COMMIT']
    config.release = ENV['OPENSHIFT_BUILD_COMMIT']
  end
end
