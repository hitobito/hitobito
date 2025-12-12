#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.
Fabricator(:role) do
  person
  start_on { 1.year.ago }
end

Role.all_types.collect { |r| r.name.to_sym }.each do |t|
  Fabricator(t, from: :role, class_name: t) do
    start_on { 1.year.ago }
  end
end
Fabricator(:future_role, from: :role) do
  start_on { Date.current.tomorrow }
end
