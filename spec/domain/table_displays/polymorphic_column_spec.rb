# frozen_string_literal: true

#  Copyright (c) 2025-2025, Schweizer Wanderwege. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

describe TableDisplays::PolymorphicColumn do
  let(:ability) { double(:ability) }

  before do
    stub_const("TestColum", Class.new(described_class))
  end

  subject(:column) { TestColum.new(ability, model_class: Event::Participation) }

  describe "label" do
    it "returns human attribute name if defined" do
      expect(column.label("additional_information")).to eq "Bemerkungen"
    end

    it "returns human attribute name if defined and passing in symbol" do
      expect(column.label(:additional_information)).to eq "Bemerkungen"
    end

    it "returns human attribute name of person" do
      expect(column.label("participant.phone_numbers")).to eq "Telefonnummern"
    end

    it "returns human attribute name of guest" do
      expect(column.label("participant.main_applicant")).to eq "Hauptperson"
    end
  end

  describe "required_model_joins" do
    it "returns empty hash if no join is needed" do
      expect(column.required_model_joins("additional_information")).to eq({})
    end

    it "returns person if attribute is on person" do
      expect(column.required_model_joins("participant.phone_numbers")).to eq({})
    end

    it "returns human attribute name of guest" do
      expect(column.required_model_joins("participant.main_applicant")).to eq({})
    end
  end
end
