# encoding: utf-8
# == Schema Information
#
# Table name: roles
#
#  id         :integer          not null, primary key
#  person_id  :integer          not null
#  group_id   :integer          not null
#  type       :string(255)      not null
#  label      :string(255)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  deleted_at :datetime
#

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.
require 'spec_helper'

describe Event::Role do

  [Event, Event::Course].each do |event_type|
    event_type.role_types.each do |part|
      context part do
        it 'must have valid permissions' do
          # although it looks like, this example is about participation.permissions and not about Participation::Permissions
          Event::Role::Permissions.should include(*part.permissions)
        end
      end
    end
  end
end
