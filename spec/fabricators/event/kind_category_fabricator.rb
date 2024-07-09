# frozen_string_literal: true

#  Copyright (c) 2021, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# == Schema Information
#
# Table name: event_kind_categories
#
#  id         :bigint           not null, primary key
#  deleted_at :datetime
#  label      :string(255)
#  order      :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

Fabricator(:event_kind_category, class_name: "Event::KindCategory") do
  label { Faker::Company.bs }
end
