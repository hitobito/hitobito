# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

require "rails_helper"

describe "roles#create", type: :request do
  let(:group) { groups(:top_group) }
  let(:person) { people(:top_leader) }

  it_behaves_like "jsonapi authorized requests" do
    let(:payload) { {} }

    subject(:make_request) do
      jsonapi_post "/api/roles", payload
    end

    describe "basic create" do
      let(:payload) do
        {
          data: {
            type: "roles",
            attributes: {
              group_id: group.id,
              person_id: person.id,
              type: Group::TopGroup::Member.sti_name
            }
          }
        }
      end

      it "creates the resource" do
        expect {
          make_request
          expect(response.status).to eq(201), response.body
        }.to change { person.roles.count }.by(1)
      end
    end
  end
end
