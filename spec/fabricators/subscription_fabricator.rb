#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.
Fabricator(:subscription) do
  subscriber { Fabricate(:person) }
end

Fabricator(:subscription_with_subscriber_with_address, from: :subscription) do
  subscriber { Fabricate(:person_with_address) }
end

Fabricator(:subscription_with_subscriber_with_phone, from: :subscription) do
  subscriber { Fabricate(:person_with_phone) }
end
