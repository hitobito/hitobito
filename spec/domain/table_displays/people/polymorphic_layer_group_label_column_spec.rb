# frozen_string_literal: true

#  Copyright (c) 2026, Hitobito AG. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe TableDisplays::People::PolymorphicLayerGroupLabelColumn, type: :helper do
  include UtilityHelper
  include ColumnHelper
  include FormatHelper

  let(:person) { people(:top_leader) }
  let(:guest) { Fabricate(:event_guest, main_applicant: event_participations(:top), first_name: "Guest1") }
  let(:ability) { Ability.new(people(:top_leader)) }

  subject(:display) { described_class.new(ability, table: nil, model_class: Person) }

  before do
    allow_any_instance_of(ActionView::Base).to receive(:parent).and_return(groups(:top_group))
    allow(display).to receive(:allowed?).and_return(true)
  end

  it "holds name of primary group layer for person" do
    expect(display.value_for(person, :layer_group)).to eq "Top"
  end

  it "is blank for event guest because there is no primary_group" do
    expect(display.value_for(guest, :layer_group)).to be_blank
  end
end
