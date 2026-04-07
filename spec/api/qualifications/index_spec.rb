# frozen_string_literal: true

#  Copyright (c) 2012-2026, Bund der Pfadfinderinnen und Pfadfinder e.V.. This file is part of
#  hitobito and licensed under the Affero General Public License version 3 or later.
#  See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

require "rails_helper"

describe "qualifications#index" do
  it_behaves_like "jsonapi authorized requests", required_scopes: [:qualifications] do
    let(:sl) { qualification_kinds(:sl) }
    let(:person) { people(:top_leader) }

    let!(:qualification) { Fabricate(:qualification, person: person, qualification_kind: sl) }
    let(:params) { {} }

    subject(:make_request) do
      jsonapi_get "/api/qualifications", params:
    end

    describe "basic fetch" do
      it "works" do
        make_request
        expect(response.status).to eq(200), response.body
        expect(d.map(&:jsonapi_type).uniq).to match_array(["qualifications"])
        expect(d.map(&:id)).to include(qualification.id)
      end
    end

    describe "filtering" do
      let(:gl) { qualification_kinds(:gl) }
      let(:bottom_member) { people(:bottom_member) }
      let!(:gl_qualification) { Fabricate(:qualification, qualification_kind: gl, person: bottom_member) }

      it "works for person_id" do
        params[:filter] = {person_id: {eq: person.id}}
        make_request
        expect(d.map(&:id)).to eq [qualification.id]
      end

      it "works for qualification_kind_id" do
        params[:filter] = {qualification_kind_id: {eq: gl.id}}
        make_request
        expect(d.map(&:id)).to eq [gl_qualification.id]
      end
    end
  end
end
