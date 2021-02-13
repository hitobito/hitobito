# encoding: utf-8

#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe EventsHelper, type: :helper do
  let(:button_label) { "Export Button" }

  describe "#export_events_ical_button" do
    it "displays ical export button" do
      expect(helper).to receive_messages(can?: true)
      expect(I18n).to receive_messages(t: button_label)
      expect(helper).to receive(:action_button)
        .with(button_label, hash_including(format: :ics), :'calendar-alt')
        .and_return(button_label)
      expect(helper.export_events_ical_button).to eq(button_label)
    end
  end
end
