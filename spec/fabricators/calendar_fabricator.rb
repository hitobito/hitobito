# frozen_string_literal: true

#  Copyright (c) 2022, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.
Fabricator(:calendar) do
  name { Faker::Lorem.words(number: 1).first.capitalize }
  description { Faker::Lorem.sentences }
  group { Group.root }
  token { SecureRandom.urlsafe_base64 }
  included_calendar_groups do |attrs|
    [Fabricate.build(:calendar_group_base, group: attrs[:group])]
  end
end

Fabricator(:calendar_group_base, class_name: :calendar_group) do
  group { Group.root }
  excluded { false }
  with_subgroups { false }
end

Fabricator(:calendar_group, from: :calendar_group_base) do
  calendar
end

Fabricator(:calendar_tag) do
  calendar { Fabricate(:calendar) }
  tag { Fabricate(:tag) }
  excluded { false }
end
