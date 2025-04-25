#  Copyright (c) 2012-2018, Schweizer Blasmusikverband. This file is part of
#  hitobito_sbv and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sbv.
require "spec_helper"

describe PeopleFilterHelper do
  include LayoutHelper
  include UtilityHelper
  include FormatHelper

  before { freeze_time }

  let(:time) { (Time.zone.now.to_f * 1000).to_i }

  describe "#people_filter_attribute_controls" do
    before { @virtual_path = "people_filters/attributes" }

    let(:attributes) { [] }
    let(:attrs_filter) { Person::Filter::Attributes.new(:arg, attributes.to_h.stringify_keys) }
    let(:node) { Capybara::Node::Simple.new(people_filter_attribute_controls(attrs_filter)) }
    let(:value) { node.find("#filters_attributes_#{time}_value") }

    it "renders custom gender control" do
      attributes << [0, {key: "gender", constraint: "equal", value: "m"}]
      expect(node).to have_select(count: 2)
      expect(node).to have_select(count: 1, disabled: true)
      expect(node).to have_select options: ["ist leer", "ist genau"]
      expect(node).to have_select options: ["weiblich", "männlich", "unbekannt"]
      expect(node).to have_select selected: "Geschlecht", disabled: true
      expect(node).to have_select selected: "männlich"
      expect(value[:name]).to eq "filters[attributes][#{time}][value]"
    end

    it "renders custom boolean control" do
      allow(Person).to receive(:filter_attrs).and_return(company: {label: "Firma", type: :boolean})
      attributes << [0, {key: "company", constraint: "equal", value: "true"}]
      expect(node).to have_select(count: 2)
      expect(node).to have_select(count: 1, disabled: true)
      expect(node).to have_select options: ["ist leer", "ist genau"]
      expect(node).to have_select options: ["ja", "nein"]
      expect(node).to have_select selected: "Firma", disabled: true
      expect(node).to have_select selected: "ja"
      expect(value[:name]).to eq "filters[attributes][#{time}][value]"
    end
  end

  describe "#people_filter_attribute_value" do
    it "renders value as is" do
      expect(people_filter_attribute_value("first_name", "dummy")).to eq "dummy"
    end

    it "uses gender label for gender value" do
      expect(people_filter_attribute_value("gender", "w")).to eq "weiblich"
      expect(people_filter_attribute_value("gender", "m")).to eq "männlich"
      expect(people_filter_attribute_value("gender", "")).to eq "unbekannt"
    end

    it "uses global true false for boolean value" do
      allow(Person).to receive(:filter_attrs).and_return(company: {label: "Firma", type: :boolean})
      expect(people_filter_attribute_value("company", "true")).to eq "ja"
      expect(people_filter_attribute_value("company", "false")).to eq "nein"
    end
  end
end
