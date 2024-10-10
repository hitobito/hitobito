#  Copyright (c) 2018, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# == Schema Information
#
# Table name: service_tokens
#
#  id                   :integer          not null, primary key
#  description          :text
#  event_participations :boolean          default(FALSE), not null
#  events               :boolean          default(FALSE)
#  groups               :boolean          default(FALSE)
#  invoices             :boolean          default(FALSE), not null
#  last_access          :datetime
#  mailing_lists        :boolean          default(FALSE), not null
#  name                 :string           not null
#  people               :boolean          default(FALSE)
#  permission           :string           default("layer_read"), not null
#  token                :string           not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  layer_group_id       :integer          not null
#

Fabricator(:service_token) do
  name { Faker::Name.name }
end
