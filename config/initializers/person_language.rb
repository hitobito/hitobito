Rails.application.config.after_initialize do
  if FeatureGate.enabled?(:person_language)
    Person::PUBLIC_ATTRS += [:language]
    Person::FILTER_ATTRS += [:language]
  end
end
