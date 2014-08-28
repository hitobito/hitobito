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

describe Event::Kind do

  let(:slk) { event_kinds(:slk) }

  it 'does not destroy translations on soft destroy' do
    expect { slk.destroy }.not_to change { Event::Kind::Translation.count }
  end

  it 'does destroy translations on hard destroy' do
    expect { slk.really_destroy! }.to change { Event::Kind::Translation.count }.by(-1)
  end

end
