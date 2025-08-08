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
      expect(value[:name]).to eq "filters[attributes][#{time}][value][]"
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

  describe "#people_filter_filter_options" do
    describe "qualifications" do
      let(:filter) do
        Person::Filter::Qualification.new("qualification", attrs)
      end

      let(:selected_kind_array) { kinds.take(2).map(&:id) }

      let(:kinds) { QualificationKind.list.without_deleted }

      let(:attrs) do
        {
          qualification_kind_ids: selected_kind_array,
          validity: "all",
          match: "one"
        }
      end

      it "returns qualification kind options with selected" do
        html = helper.people_filter_qualification_kind_options(filter)
        kinds.each do |kind|
          if selected_kind_array.include?(kind.id)
            expect(html).to include("<option selected=\"selected\" value=\"#{kind.id}\">#{kind.label}</option>")
          else
            expect(html).to include("<option value=\"#{kind.id}\">#{kind.label}</option>")
          end
        end
      end

      it "returns qualification kind options without selected" do
        html = helper.people_filter_qualification_kind_options(nil)
        kinds.each do |kind|
          expect(html).to include("<option value=\"#{kind.id}\">#{kind.label}</option>")
        end
      end

      it "returns qualification validity options with selected" do
        html = helper.people_filter_qualification_validity_options(filter)
        expect(html).to include("<option selected=\"selected\" value=\"#{attrs[:validity]}\">Alle jemals erteilten Qualifikationen</option>")
      end
    end

    describe "roles" do
      let(:filter) { Person::Filter::Role.new("roles", attrs) }
      let(:selected_types_array) { [Group::BottomLayer::Leader.id, Group::GlobalGroup::Member.id] }
      let(:attrs) do
        {
          role_type_ids: selected_types_array,
          kind: "active"
        }
      end

      it "returns role types options with selected" do
        allow(view).to receive(:group).and_return(Group.first)
        html = helper.people_filter_role_options(filter)
        expect(html).to include("<option selected=\"selected\" class=\"same_layer group\" value=\"#{Group::GlobalGroup::Member.id}\">Bottom Layer -&gt; Global Group -&gt; Member</option>")
        expect(html).to include("<option selected=\"selected\" class=\"same_layer same-group\" value=\"#{Group::BottomLayer::Leader.id}\">Bottom Layer -&gt; Leader</option>")
      end

      it "returns role kinds options without selected" do
        html = helper.people_filter_role_kind_options(nil)
        expect(html).to include("<option value=\"active\">aktive Rollen</option>")
        expect(html).to include("<option value=\"created\">erstellte Rollen</option>")
        expect(html).to include("<option value=\"deleted\">gelöschte Rollen</option>")
        expect(html).to include("<option value=\"inactive\">inaktive oder nie vorhandene Rollen</option>")
        expect(html).to include("<option value=\"inactive_but_existing\">inaktive aber zu einer anderen Zeit vorhandene Rollen</option>")
      end

      it "returns role kinds options with selected" do
        html = helper.people_filter_role_kind_options(filter)
        expect(html).to include("<option selected=\"selected\" value=\"active\">aktive Rollen</option>")
      end
    end

    describe "tags" do
      let(:present_tags) { [Fabricate(:tag), Fabricate(:tag)] }
      let(:absent_tags) { [Fabricate(:tag), Fabricate(:tag)] }
      let(:filter_chain) do
        {
          tag: Person::Filter::Tag.new("tag", {names: present_tags}),
          tag_absence: Person::Filter::TagAbsence.new("tag", {names: absent_tags})
        }
      end

      it "returns tag options with selected" do
        html_hash = helper.people_filter_tags_options(filter_chain)
        check_tag_options(present_tags, html_hash[:present], absent_tags)
        check_tag_options(absent_tags, html_hash[:absent], present_tags)
      end

      def check_tag_options(tag_array, html, non_selected)
        tag_array.each do |tag|
          expect(html).to include("<option selected=\"selected\" value=\"#{tag}\">#{tag}</option>")
        end
        non_selected.each do |tag|
          expect(html).to include("<option value=\"#{tag}\">#{tag}</option>")
        end
      end
    end
  end
end
