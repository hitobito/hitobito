# == Schema Information
#
# Table name: event_kinds
#
#  id                     :integer          not null, primary key
#  application_conditions :text
#  deleted_at             :datetime
#  general_information    :text
#  label                  :string           not null
#  minimum_age            :integer
#  short_name             :string
#  created_at             :datetime
#  updated_at             :datetime
#  kind_category_id       :integer
#

#  Copyright (c) 2012-2014, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Event::Kind do
  let(:slk) { event_kinds(:slk) }

  it "does not destroy translations on soft destroy" do
    expect { slk.destroy }.not_to change { Event::Kind::Translation.count }
  end

  it "does destroy translations on hard destroy" do
    expect { slk.really_destroy! }.to change { Event::Kind::Translation.count }.by(-1)
  end

  context "#list" do
    it "orders by short_name, deleted last" do
      expect(Event::Kind.list).to match_array([
        event_kinds(:fk),
        event_kinds(:glk),
        event_kinds(:slk),
        event_kinds(:old)
      ])
    end
  end
end
