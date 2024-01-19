# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

require 'rails_helper'

RSpec.describe "people#update", type: :request do
  it_behaves_like 'jsonapi authorized requests' do
    let(:person) { people(:top_leader) }
    let(:payload) { {} }

    subject(:make_request) do
      jsonapi_put "/api/people/#{person.id}", payload
    end

    describe 'basic update' do
      let(:payload) do
        {
          data: {
            id: person.id.to_s,
            type: 'people',
            attributes: {
              first_name: 'Bobby'
            }
          }
        }
      end

      it 'updates the resource' do
        expect(PersonResource).to receive(:find).and_call_original
        expect {
          make_request
          expect(response.status).to eq(200), response.body
        }.to change { person.reload.first_name }.to('Bobby')
      end
    end
  end
end
