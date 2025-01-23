# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

shared_examples "table display" do |column:, header:, permission:, value: "", export_value: nil|
  subject(:display) { described_class.new(ability, table: table, model_class: Person) }

  subject(:node) { Capybara::Node::Simple.new(table.to_html) }

  before do
    allow(controller).to receive(:current_user).at_most(:once).and_return(person)
    allow(table).to receive(:template).at_least(:once).and_return(view)
  end

  it "requires #{permission} as permission" do
    expect(display.required_permission(column)).to eq permission
  end

  it "renders #{header} as header" do
    display.render(column)
    expect(node).to have_css "th", text: header
  end

  it "renders #{value} as value" do
    display.render(column)
    expect(node).to have_css "td", text: value
  end

  it "uses #{value} in export" do
    expect(resolve_export_value(column).to_s).to eq(export_value || value)
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
