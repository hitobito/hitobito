#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.
Fabricator(:group) do
  name { Faker::Name.name }
end

Group.all_types.collect { |g| g.name.to_sym }.each do |t|
  Fabricator(t, from: :group, class_name: t)
end
