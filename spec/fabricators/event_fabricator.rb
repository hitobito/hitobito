#  Copyright (c) 2012-2023, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.
Fabricator(:event) do
  name { "Eventus" }
  groups { [Group.all_types.detect { |t| t.event_types.include?(Event) }.first] }
  before_create do |event|
    event.dates.build(start_at: Time.zone.local(2012, 5, 11)) if event.dates.empty?
  end
end

Fabricator(:course, from: :event, class_name: :"Event::Course") do
  groups { [Group.all_types.detect { |t| t.event_types.include?(Event::Course) }.first] }
  kind { Event::Kind.where(short_name: "SLK").first }
  number { 123 }
  priorization { true }
  requires_approval { true }
end
