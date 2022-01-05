# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

Person.seed(:email,
  {company_name: 'Puzzle ITC',
   company: true,
   email: Settings.root_email,
   confirmed_at: Time.now}
)


if !Rails.env.test? # don't seed in tests as it causes some tests to fail
  require Rails.root.join('db', 'seeds', 'support', 'location_seeder')
  LocationSeeder.new.seed
end
