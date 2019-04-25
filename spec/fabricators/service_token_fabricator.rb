#  Copyright (c) 2018, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.
# == Schema Information
#
# Table name: service_tokens
#
#  id             :integer          not null, primary key
#  layer_group_id :integer          not null
#  name           :string(255)      not null
#  description    :text(65535)
#  token          :string(255)      not null
#  last_access    :datetime
#  people         :boolean          default(FALSE)
#  people_below   :boolean          default(FALSE)
#  groups         :boolean          default(FALSE)
#  events         :boolean          default(FALSE)
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#

Fabricator(:service_token) do
  name { Faker::Name.name }
end
