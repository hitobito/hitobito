# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe TableDisplays::People::PrimaryGroupColumn, type: :helper do
  include UtilityHelper
  include FormatHelper

  let(:person) { people(:top_leader).decorate }
  let(:ability) { Ability.new(person) }
  let(:table) { StandardTableBuilder.new([person], self) }

  before do
    allow_any_instance_of(ActionView::Base).to receive(:parent).and_return(groups(:top_group))
  end

  it_behaves_like "table display", {
    column: :primary_group_id,
    header: "Hauptgruppe",
    value: "TopGroup",
    permission: :show
  }

  context "when the person has no primary group set" do
    subject(:display) { described_class.new(ability, table: table, model_class: Person) }

    subject(:node) { Capybara::Node::Simple.new(table.to_html) }

    before do
      allow(table).to receive(:template).at_least(:once).and_return(view)
      person.update_column(:primary_group_id, nil)
    end

    it "view renders nothing as value" do
      display.render(:primary_group_id)
      expect(node.find("td").all("*").length).to eq 0
      expect(node.find("td").text).to eq ""
    end

    it "export uses empty value if person has no primary group set" do
      expect(resolve_export_value(:primary_group_id).to_s).to eq("")
    end
  end

  # helper method to imitate resolving of attr usually done in TableDisplayRow
  def resolve_export_value(column)
    display.value_for(person.object, column) do |target, target_attr|
      if respond_to?(target_attr, true)
        send(target_attr)
      elsif target.respond_to?(target_attr)
        target.public_send(target_attr)
      end
    end
  end
end
