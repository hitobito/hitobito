# == Schema Information
#
# Table name: roles
#
#  id         :integer          not null, primary key
#  deleted_at :datetime
#  label      :string(255)
#  type       :string(255)      not null
#  created_at :datetime
#  updated_at :datetime
#  group_id   :integer          not null
#  person_id  :integer          not null
#
# Indexes
#
#  index_roles_on_person_id_and_group_id  (person_id,group_id)
#  index_roles_on_type                    (type)
#

#  Copyright (c) 2014, CEVI Regionalverband ZH-SH-GL. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class RoleSerializer < ApplicationSerializer
  schema do
    json_api_properties

    group_template_link "roles.group"
    group_template_link "roles.layer_group"

    property :role_type, item.class.label
    map_properties :label, :created_at, :updated_at, :deleted_at

    entity :group, item.group, GroupLinkSerializer
    entity :layer_group, item.group.layer_group, GroupLinkSerializer
  end
end
