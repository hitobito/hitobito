#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# == Schema Information
#
# Table name: event_kinds
#
#  id                     :integer          not null, primary key
#  application_conditions :text
#  deleted_at             :datetime
#  general_information    :text
#  label                  :string           not null
#  minimum_age            :integer
#  short_name             :string
#  created_at             :datetime
#  updated_at             :datetime
#  kind_category_id       :integer
#

Fabricator(:event_kind, class_name: "Event::Kind") do
  label { Faker::Company.bs }
  general_information { Faker::Lorem.sentence }
end
