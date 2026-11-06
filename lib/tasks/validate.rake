# frozen_string_literal: true

namespace :validate do
  desc "Validate all peoples primary and additional e-mail addresses, optionally block invalid ones"
  task :people_email, [:block] => :environment do |_task, args|
    Contactable::EmailValidator.new(block: args[:block] == "block").validate_people
  end

  desc "Validate all peoples addresses"
  task people_address: :environment do
    Contactable::AddressValidator.new.validate_people
  end
end
