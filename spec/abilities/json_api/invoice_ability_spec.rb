# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe JsonApi::InvoiceAbility do

  let(:top_group) { groups(:top_group) }
  let(:bottom_member) { people(:bottom_member) }

  context 'person' do
    def accessible_by(person, model_class = Invoice)
      ability = described_class.new(Ability.new(people(person)))
      model_class.all.accessible_by(ability)
    end

    it 'filters invoices according to layer' do
      expect(accessible_by(:bottom_member)).to have(2).items
      expect(accessible_by(:top_leader)).to be_empty

      invoice = Fabricate(:invoice, group: top_group, recipient: bottom_member)
      expect(accessible_by(:top_leader)).to eq [invoice]
      expect(accessible_by(:bottom_member)).to have(2).items
    end

    it 'filters invoices items according layer' do
      expect(accessible_by(:bottom_member, InvoiceItem)).to have(3).items
      expect(accessible_by(:top_leader, InvoiceItem)).to be_empty

      invoice = Fabricate(:invoice, group: top_group, recipient: bottom_member)
      item = invoice.invoice_items.create!(name: 'test', unit_cost: 1)
      expect(accessible_by(:top_leader, InvoiceItem)).to eq [item]
      expect(accessible_by(:bottom_member, InvoiceItem)).to have(3).items
    end
  end

  context 'service token' do
    def accessible_by(token, model_class = Invoice)
      ability = described_class.new(TokenAbility.new(service_tokens(token)))
      model_class.all.accessible_by(ability)
    end

    it 'filters invoices according to layer' do
      expect(accessible_by(:permitted_bottom_layer_token)).to have(2).items
      expect(accessible_by(:permitted_top_layer_token)).to be_empty

      invoice = Fabricate(:invoice, group: top_group, recipient: bottom_member)
      expect(accessible_by(:permitted_top_layer_token)).to eq [invoice]
      expect(accessible_by(:permitted_bottom_layer_token)).to have(2).items
    end

    it 'filters invoices items according layer' do
      expect(accessible_by(:permitted_bottom_layer_token, InvoiceItem)).to have(3).items
      expect(accessible_by(:permitted_top_layer_token, InvoiceItem)).to be_empty

      invoice = Fabricate(:invoice, group: top_group, recipient: bottom_member)
      item = invoice.invoice_items.create!(name: 'test', unit_cost: 1)
      expect(accessible_by(:permitted_top_layer_token, InvoiceItem)).to eq [item]
      expect(accessible_by(:permitted_bottom_layer_token, InvoiceItem)).to have(3).items
    end
  end
end
