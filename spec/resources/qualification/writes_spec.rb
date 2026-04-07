# frozen_string_literal: true

#  Copyright (c) 2012-2026, Bund der Pfadfinderinnen und Pfadfinder e.V.. This file is part of
#  hitobito and licensed under the Affero General Public License version 3 or later.
#  See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

require "spec_helper"

describe QualificationResource, type: :resource do
  let(:user) { people(:top_leader) }
  let(:ability) { Ability.new(user) }
  let(:qualification_kind) { qualification_kinds(:sl) }

  describe "creating" do
    let(:payload) do
      {
        data: {
          type: "qualifications",
          attributes: {
            person_id: user.id,
            qualification_kind_id: qualification_kind.id,
            start_at: "2024-01-01",
            finish_at: "2024-12-31",
            qualified_at: "2024-01-01",
            origin: "test"
          }
        }
      }
    end

    let(:instance) { QualificationResource.build(payload) }

    it "works" do
      expect {
        expect(instance.save).to eq(true), instance.errors.full_messages.to_sentence
      }.to change { Qualification.count }.by(1)

      qualification = Qualification.last
      expect(qualification.person).to eq person
      expect(qualification.qualification_kind).to eq qualification_kind
      expect(qualification.start_at).to eq Date.parse("2024-01-01")
      expect(qualification.origin).to eq "test"
    end

    context "not authorized" do
      let(:ability) { Ability.new(people(:bottom_member)) }

      it "raises AccessDenied" do
        expect {
          expect(instance.save).to eq(false)
        }.to raise_error(CanCan::AccessDenied)
      end
    end
  end

  describe "destroying" do
    let!(:qualification) { Fabricate(:qualification, person: person) }
    let(:instance) { QualificationResource.find(id: qualification.id) }

    it "works" do
      expect {
        expect(instance.destroy).to eq(true)
      }.to change { Qualification.count }.by(-1)
    end

    context "not authorized" do
      let(:ability) { Ability.new(people(:bottom_member)) }

      it "raises RecordNotFound" do
        expect {
          expect(instance.destroy).to eq(false)
        }.to raise_error(Graphiti::Errors::RecordNotFound)
      end
    end
  end
end
