# frozen_string_literal: true

#  Copyright (c) 2020-2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

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
