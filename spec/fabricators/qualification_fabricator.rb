#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.
Fabricator(:qualification) do
  person
  qualification_kind
  start_at { (0..24).to_a.sample.months.ago }
end
