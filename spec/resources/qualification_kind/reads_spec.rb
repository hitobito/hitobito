# frozen_string_literal: true

#  Copyright (c) 2012-2026, Bund der Pfadfinderinnen und Pfadfinder e.V.. This file is part of
#  hitobito and licensed under the Affero General Public License version 3 or later.
#  See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

require "spec_helper"

describe QualificationKindResource, type: :resource do
  describe "serialization" do
    let!(:qualification_kind) { Fabricate(:qualification_kind) }

    it "works" do
      render
      data = jsonapi_data[0]
      expect(data.id).to eq(qualification_kind.id)
      expect(data.jsonapi_type).to eq("qualification_kinds")
      expect(data.label).to eq(qualification_kind.label)
      expect(data.description).to eq(qualification_kind.description)
      expect(data.validity).to eq(qualification_kind.validity)
      expect(data.reactivateable).to eq(qualification_kind.reactivateable)
      expect(data.required_training_days).to eq(qualification_kind.required_training_days.to_f)
    end
  end
end
