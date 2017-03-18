# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'


describe GroupsHelper, type: :helper do

  describe '#export_events_ical_button' do
    let(:entry) { people(:top_leader) }
    subject { helper.export_events_ical_button }

    xit do
      allow(helper).to receive(:can?).and_return(true)
      #expect(helper).to receive(:action_button).with(I18n.t('event.lists.courses.ical_export_button'), )
    end
  end
end

