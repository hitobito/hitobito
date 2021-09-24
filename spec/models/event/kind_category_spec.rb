# encoding: utf-8
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

#  Copyright (c) 2012-2014, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Event::KindCategory do

  let!(:abk) { event_kind_categories(:abk) }
  let!(:bsk) { event_kind_categories(:bsk) }
  let!(:afk) { event_kind_categories(:afk) }

  it 'orders categories by order column' do
    expect(Event::KindCategory.pluck(:order).to_a).to eq [1, 2, 3]
  end

  it 'handles nil as order' do
    bsk.update!(order: nil)
    expect(Event::KindCategory.pluck(:order).to_a).to eq [nil, 1, 3]
  end

end
