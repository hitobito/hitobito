# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.
# == Schema Information
#
# Table name: event_applications
#
#  id                   :integer          not null, primary key
#  priority_1_id        :integer          not null
#  priority_2_id        :integer
#  priority_3_id        :integer
#  approved             :boolean          default(FALSE), not null
#  rejected             :boolean          default(FALSE), not null
#  waiting_list         :boolean          default(FALSE), not null
#  waiting_list_comment :text
#

require "spec_helper"

describe Event::Application do
  let(:course) { Fabricate(:course, groups: [groups(:top_layer)]) }

  subject { Event::Application.new }

  context ".pending" do
    let(:course) { Fabricate(:course, groups: [groups(:top_layer)], kind: event_kinds(:slk)) }

    subject { Event::Application.pending }

    context "with assigned event role" do
      let(:participation) { Fabricate(:event_participation, person: people(:top_leader)) }

      before { Fabricate(Event::Role::Leader.name.to_sym, participation: participation) }

      it "does not include non rejected appliations" do
        application = Fabricate(:event_application, priority_1: course, participation: participation, rejected: false)
        is_expected.to eq([])
      end

      it "does not include rejected applications" do
        application = Fabricate(:event_application, priority_1: course, participation: participation, rejected: true)
        is_expected.to eq([])
      end
    end

    context "without event role" do
      let(:participation) { Fabricate(:event_participation, person: people(:top_leader)) }

      it "does not include rejected appliations" do
        application = Fabricate(:event_application, priority_1: course, rejected: true, participation: participation)
        is_expected.to eq([])
      end

      it "includes non reject applications" do
        application = Fabricate(:event_application, priority_1: course, rejected: false, participation: participation)
        is_expected.to eq([application])
      end
    end
  end
end
