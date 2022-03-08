Rails.application.config.after_initialize do
  # some rake tasks do not load db, so just extend
  # public attrs if db is loaded
  if ActiveRecord::Base.connection.table_exists?('people')
    Person::PUBLIC_ATTRS += [:language] if FeatureGate.enabled?(:person_language)
  end
end
