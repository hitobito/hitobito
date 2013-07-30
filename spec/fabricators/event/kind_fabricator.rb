# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# == Schema Information
#
# Table name: event_kinds
#
#  id          :integer          not null, primary key
#  label       :string(255)      not null
#  short_name  :string(255)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  deleted_at  :datetime
#  minimum_age :integer
#

Fabricator(:event_kind, class_name: 'Event::Kind') do
  label { Faker::Company.bs }
end
