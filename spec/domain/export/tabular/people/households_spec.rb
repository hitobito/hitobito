#  Copyright (c) 2012-2018, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Export::Tabular::People::Households do
  let(:leader) { people(:top_leader) }
  let(:member) { people(:bottom_member) }

  def households(list = [])
    Export::Tabular::People::Households.new(list)
  end

  context "header" do
    it "includes name, address attributes and layer group columns" do
      expect(households.attributes).to eq [:name, :address, :zip_code, :town,
                                           :country, :layer_group,]
    end

    it "translates name, address attributes and layer group columns" do
      expect(households.attribute_labels.values).to eq ["Name", "Adresse", "PLZ",
                                                        "Ort", "Land", "Hauptebene",]
    end
  end

  it "accepts non household people" do
    data = households([leader]).data_rows.to_a
    expect(data).to have(1).item
    expect(data[0]).to eq ["Top Leader", nil, nil, "Supertown", nil, "Top"]
  end

  it "accepts single person array" do
    data = households([people(:top_leader)]).data_rows.to_a
    expect(data).to have(1).item
    expect(data[0]).to eq ["Top Leader", nil, nil, "Supertown", nil, "Top"]
  end

  it "aggregates household people, uses first person""s address" do
    leader.update(household_key: 1)
    member.update(household_key: 1)

    data = households([member, leader]).data_rows.to_a
    expect(data).to have(1).item
    expect(data[0].shift).to eq "Bottom Member, Top Leader"
    expect(data[0]).to eq ["Greatstreet 345", "3456", "Greattown", "Schweiz", "Bottom One"]
  end
end
