#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"
require "csv"

describe Export::Tabular::Groups::List do
  let(:group) { groups(:bottom_layer_one) }

  let(:list) { group.self_and_descendants.without_deleted.includes(:contact) }
  let(:data) { Export::Tabular::Groups::List.csv(list) }
  let(:csv) { CSV.parse(data, headers: true, col_sep: Settings.csv.separator) }

  subject { csv }

  its(:headers) do
    is_expected.to == %w[Id Elterngruppe Name Kurzname Gruppentyp Haupt-E-Mail Adresse PLZ Ort Land Ebene Beschreibung]
  end

  it "has 4 items" do
    expect(subject.size).to eq(4)
  end

  context "first row" do
    subject { csv[0] }

    its(["Id"]) { is_expected.to == group.id.to_s }
    its(["Elterngruppe"]) { is_expected.to == group.parent_id.to_s }
    its(["Name"]) { is_expected.to == group.name }
    its(["Kurzname"]) { is_expected.to == group.short_name }
    its(["Gruppentyp"]) { is_expected.to == "Bottom Layer" }
    its(["Haupt-E-Mail"]) { is_expected.to == group.email }
    its(["Adresse"]) { is_expected.to == group.address }
    its(["PLZ"]) { is_expected.to == group.zip_code.to_s }
    its(["Ort"]) { is_expected.to == group.town }
    its(["Land"]) { is_expected.to == group.country_label }
    its(["Ebene"]) { is_expected.to == group.id.to_s }
  end

  context "group with contact" do
    let(:contact) { people(:bottom_member) }

    subject { csv[1] }

    its(["Elterngruppe"]) { is_expected.to == group.id.to_s }
    its(["Ebene"]) { is_expected.to == group.id.to_s }
    its(["Haupt-E-Mail"]) { is_expected.to == groups(:bottom_group_one_one).email }
    its(["Adresse"]) { is_expected.to == contact.address }
    its(["PLZ"]) { is_expected.to == contact.zip_code.to_s }
    its(["Ort"]) { is_expected.to == contact.town }
    its(["Land"]) { is_expected.to == contact.country_label }
  end
end
