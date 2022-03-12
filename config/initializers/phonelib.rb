Rails.application.config.after_initialize do
  Phonelib.default_country = Settings.phone_number.default_country
end
