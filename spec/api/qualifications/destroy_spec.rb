# frozen_string_literal: true

#  Copyright (c) 2012-2026, Bund der Pfadfinderinnen und Pfadfinder e.V.. This file is part of
#  hitobito and licensed under the Affero General Public License version 3 or later.
#  See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

require "rails_helper"

describe "qualifications#destroy" do
  let(:person) { people(:top_leader) }
  let(:sl) { qualification_kinds(:sl) }
  let!(:qualification) { Fabricate(:qualification, person: person, qualification_kind: sl) }

  it_behaves_like "jsonapi authorized requests", required_scopes: [:qualifications] do
    subject(:make_request) do
      jsonapi_delete "/api/qualifications/#{qualification.id}"
    end

    describe "basic destroy" do
      it "destroys the resource" do
        expect {
          make_request
          expect(response.status).to eq(200), response.body
        }.to change { person.qualifications.count }.by(-1)
      end
    end
  end
end
