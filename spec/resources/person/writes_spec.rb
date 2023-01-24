#  frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Wanderwege. This file is part of
#  hitobito_sww and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sww.

require 'spec_helper'

RSpec.describe PersonResource, type: :resource do
  describe 'creating' do
    let(:payload) do
      {
        data: {
          type: 'people',
          attributes: Fabricate.attributes_for(:person).except('confirmed_at')
        }
      }
    end

    let(:instance) do
      PersonResource.build(payload)
    end

    it 'works' do
      expect {
        expect(instance.save).to eq(true), instance.errors.full_messages.to_sentence
      }.to change { Person.count }.by(1)
    end
  end

  describe 'updating' do
    let!(:person) { Fabricate(:person, first_name: 'Franz', updated_at: 1.second.ago) }

    let(:payload) do
      {
        id: person.id.to_s,
        data: {
          id: person.id.to_s,
          type: 'people',
          attributes: {
            first_name: 'Joseph'
          }
        }
      }
    end

    let(:instance) do
      PersonResource.find(payload)
    end

    it 'works (add some attributes and enable this spec)' do
      expect {
        expect(instance.update_attributes).to eq(true)
      }.to change { person.reload.updated_at }
       .and change { person.first_name }.to('Joseph')
    end
  end

  describe 'destroying' do
    let!(:person) { Fabricate(:person) }

    let(:instance) do
      PersonResource.find(id: person.id)
    end

    it 'works' do
      expect {
        expect(instance.destroy).to eq(true)
      }.to change { Person.count }.by(-1)
    end
  end
end
