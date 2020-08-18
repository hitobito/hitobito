Raven.configure do |config|
  config.sanitize_fields = Rails.application.config.filter_parameters.map(&:to_s)

  config.release = Rails.application.class.versions(Rails.root.join('VERSION')).first.chomp

  if ENV['SENTRY_CURRENT_ENV'].blank?
    project, stage = [
      ENV['OPENSHIFT_BUILD_NAMESPACE'], # hit-jubla-int
      ENV['RAILS_DB_NAME'],             # hit_jubla_development
      "hitobito-#{Rails.env}"           # hitobito-development
    ].compact.first.split(/[-_]/)[-2..-1]

    config.tags[:project]      = project
    config.current_environment = case stage
                                 when /^int/i  then 'integration'
                                 when /^prod/i then 'production'
                                 when /^sta/i  then 'staging'
                                 when /^dev/i  then 'development'
                                 else stage
                                 end
  end
end
