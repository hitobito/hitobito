# frozen_string_literal: true

namespace :validate do
  desc "Validate all peoples primary and additional e-mail addresses"
  task :people_email => :environment do
    Contactable::EmailValidator.new.validate_people
  end

  desc "Validate all peoples addresses"
  task :people_address => :environment do
    Contactable::AddressValidator.new.validate_people
  end
end
