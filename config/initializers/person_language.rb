Rails.application.config.after_initialize do
  Person::PUBLIC_ATTRS += [:language] if FeatureGate.enabled?(:person_language)
end
