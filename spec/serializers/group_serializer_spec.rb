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

require 'spec_helper'

describe GroupSerializer do

  let(:group) { groups(:top_group).decorate }
  let(:controller) { double().as_null_object }

  let(:serializer) { GroupSerializer.new(group, controller: controller)}
  let(:hash) { serializer.to_hash }

  subject { hash[:groups].first }

  it 'has different entities' do
    links = subject[:links]
    expect(links[:parent]).to eq(group.parent_id.to_s)
    expect(links).not_to have_key(:children)
    expect(links[:layer_group]).to eq(group.parent_id.to_s)
    expect(links[:hierarchies].size).to eq(2)
  end

  it 'does not include deleted children' do
    a = Fabricate(Group::GlobalGroup.name.to_sym, parent: group)
    b = Fabricate(Group::GlobalGroup.name.to_sym, parent: group)
    b.update!(deleted_at: 1.month.ago)

    expect(subject[:links][:children].size).to eq(1)
  end
end
