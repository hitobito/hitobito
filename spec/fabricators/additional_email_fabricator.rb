#  Copyright (c) 2014, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.
Fabricator(:additional_email) do
  contactable { Fabricate(:person) }
  email { "#{Faker::Internet.user_name}@hitobito.example.com" }
  label { "Privat" }
end
