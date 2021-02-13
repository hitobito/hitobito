# encoding: utf-8
# == Schema Information
#
# Table name: groups
#
#  id                          :integer          not null, primary key
#  parent_id                   :integer
#  lft                         :integer
#  rgt                         :integer
#  name                        :string(255)      not null
#  short_name                  :string(31)
#  type                        :string(255)      not null
#  email                       :string(255)
#  address                     :string(1024)
#  zip_code                    :integer
#  town                        :string(255)
#  country                     :string(255)
#  contact_id                  :integer
#  created_at                  :datetime
#  updated_at                  :datetime
#  deleted_at                  :datetime
#  layer_group_id              :integer
#  creator_id                  :integer
#  updater_id                  :integer
#  deleter_id                  :integer
#  require_person_add_requests :boolean          default(FALSE), not null
#  description                 :text(65535)
#

#  Copyright (c) 2014, CEVI Regionalverband ZH-SH-GL. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe GroupListSerializer do

  let(:group) { groups(:top_group).decorate }
  let(:controller) { double().as_null_object }
  let(:serializer) { ListSerializer.new(Group.where(id: group.id), serializer: GroupListSerializer, 
                                                                   controller: controller) }

  subject(:hash) { serializer.to_hash[:groups].first }

  it "has different entities" do
    expect(hash[:id]).to eq(group.id)
    expect(hash[:parent_id]).to eq(group.parent_id)
    expect(hash[:type]).to eq(group.type.to_s)
  end
end
