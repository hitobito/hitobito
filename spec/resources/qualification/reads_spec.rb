# frozen_string_literal: true

#  Copyright (c) 2012-2026, Bund der Pfadfinderinnen und Pfadfinder e.V.. This file is part of
#  hitobito and licensed under the Affero General Public License version 3 or later.
#  See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

require "spec_helper"

describe QualificationResource do
  let(:person) { people(:top_leader) }
  let(:qualification_kind) { qualification_kinds(:sl) }
  let!(:qualification) { Fabricate(:qualification, person: person, qualification_kind:) }

  describe "serialization" do
    context "with appropriate permission" do
      it "works" do
        render
        data = jsonapi_data[0]
        expect(data.id).to eq(qualification.id)
        expect(data.jsonapi_type).to eq("qualifications")
        expect(data.person_id).to eq(person.id)
        expect(data.qualification_kind_id).to eq(qualification.qualification_kind_id)
        expect(data.start_at).to eq(qualification.start_at.to_s)
        expect(data.finish_at).to eq(qualification.finish_at.to_s)
        expect(data.qualified_at).to eq(qualification.qualified_at.to_s.presence)
        expect(data.origin).to eq(qualification.origin)
      end
    end

    context "without appropriate permission" do
      let(:ability) { Ability.new(Fabricate(:person)) }

      it "does not expose data" do
        render
        expect(jsonapi_data).to eq([])
      end
    end
  end

  describe "including" do
    it "may include person" do
      params[:include] = "person"
      render
      person = d[0].sideload(:person)
      expect(person.email).to eq "top_leader@example.com"
    end

    it "may include qualification_kind" do
      params[:include] = "qualification_kind"
      render
      quali_kind = d[0].sideload(:qualification_kind)
      expect(quali_kind.label).to eq "Super Lead"
    end
  end
end
