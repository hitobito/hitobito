# frozen_string_literal: true

#  Copyright (c) 2021, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# == Schema Information
#
# Table name: related_role_types
#
#  id            :integer          not null, primary key
#  relation_type :string(255)
#  role_type     :string(255)      not null
#  relation_id   :integer
#
# Indexes
#
#  index_related_role_types_on_relation_id_and_relation_type  (relation_id,relation_type)
#  index_related_role_types_on_role_type                      (role_type)
#

class RelatedRoleTypeSerializer < ApplicationSerializer
  schema do
    json_api_properties

    map_properties :role_type
  end
end
