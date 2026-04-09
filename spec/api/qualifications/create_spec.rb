# frozen_string_literal: true

#  Copyright (c) 2012-2026, Bund der Pfadfinderinnen und Pfadfinder e.V.. This file is part of
#  hitobito and licensed under the Affero General Public License version 3 or later.
#  See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

require "rails_helper"

describe "qualifications#create" do
  let(:person) { people(:top_leader) }
  let(:sl) { qualification_kinds(:sl) }

  it_behaves_like "jsonapi authorized requests", required_scopes: [:qualifications] do
    let(:payload) {
      {
        data: {
          type: "qualifications",
          attributes: {
            person_id: person.id,
            qualification_kind_id: sl.id,
            start_at: "2024-01-01",
            finish_at: "2024-12-31",
            qualified_at: "2024-01-01",
            origin: "test"
          }
        }
      }
    }

    subject(:make_request) do
      jsonapi_post "/api/qualifications", payload
    end

    describe "basic create" do
      it "creates the resource" do
        expect {
          make_request
          expect(response.status).to eq(201), response.body
        }.to change { person.qualifications.count }.by(1)
      end
    end
  end
end
