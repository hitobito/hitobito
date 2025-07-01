# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe TableDisplays::People::LayerGroupLabelColumn, type: :helper do
  include UtilityHelper
  include FormatHelper

  let(:person) { people(:top_leader).decorate }
  let(:ability) { Ability.new(person) }
  let(:table) { StandardTableBuilder.new([person], self) }

  before do
    allow_any_instance_of(ActionView::Base).to receive(:parent).and_return(groups(:top_group))
  end

  it_behaves_like "table display", {
    column: :layer_group,
    header: "Hauptebene",
    value: "Top",
    permission: :show
  }

  context "inside job" do
    subject(:display) { described_class.new(ability, table: nil, model_class: Person) }

    let(:content) { display.value_for(person, :layer_group) }

    it "holds name of primary group layer" do
      expect(content).to eq "Top"
    end

    it "is blank when primary group is missing" do
      person.update(primary_group: nil)
      expect(content).to be_blank
    end
  end
end
