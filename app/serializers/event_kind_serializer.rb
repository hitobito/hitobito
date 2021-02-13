#  Copyright (c) 2018, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.
#
# == Schema Information
#
# Table name: event_kinds
#
#  id          :integer          not null, primary key
#  created_at  :datetime
#  updated_at  :datetime
#  deleted_at  :datetime
#  minimum_age :integer
#

class EventKindSerializer < ApplicationSerializer
  schema do
    json_api_properties

    map_properties :label,
      :short_name,
      :minimum_age,
      :general_information,
      :application_conditions
  end
end
