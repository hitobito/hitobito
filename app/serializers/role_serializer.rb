# encoding: utf-8
# == Schema Information
#
# Table name: roles
#
#  id         :integer          not null, primary key
#  person_id  :integer          not null
#  group_id   :integer          not null
#  type       :string           not null
#  label      :string
#  created_at :datetime
#  updated_at :datetime
#  deleted_at :datetime
#


#  Copyright (c) 2014, CEVI Regionalverband ZH-SH-GL. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class RoleSerializer < ApplicationSerializer
  schema do
    json_api_properties

    group_template_link 'roles.group'
    group_template_link 'roles.layer_group'

    property :role_type, item.class.label
    map_properties :label, :created_at, :updated_at, :deleted_at

    entity :group, item.group, GroupLinkSerializer
    entity :layer_group, item.group.layer_group, GroupLinkSerializer
  end

end
