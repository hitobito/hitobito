# encoding: utf-8

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
    expect { slk.destroy! }.to change { Event::Kind::Translation.count }.by(-1)
  end

end
