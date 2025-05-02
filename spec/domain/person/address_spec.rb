# frozen_string_literal: true

#  Copyright (c) 2012-2025, Die Mitte Schweiz. This file is part of
#  hitobito_cvp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Person::Address do
  let(:person) { people(:top_leader) }
  let(:label) { nil }
  let(:name) { nil }
  let(:address) { described_class.new(person, label:, name: nil) }

  def build_additional_address(attrs)
    person.additional_addresses.build(attrs).tap(&:valid?)
  end

  shared_examples "common address behaviour" do |country_label:, postbox:, company:, uses_additional_address_name: true, label_handling: true|
    context "common" do
      it "renders name, text and town with zip code" do
        expect(text).to eq <<~TEXT
          Top Leader
          Greatstreet 345
          3456 Greattown
        TEXT
      end

      if country_label
        it "country is rendered using country label" do
          person.country = "DE"
          expect(text).to eq <<~TEXT.chomp
            Top Leader
            Greatstreet 345
            3456 Greattown
            Deutschland
          TEXT
        end
      else
        it "country is rendered using country TLD" do
          person.country = "DE"
          expect(text).to eq <<~TEXT.chomp
            Top Leader
            Greatstreet 345
            3456 Greattown
            DE
          TEXT
        end
      end

      if postbox
        it "postbox is rendered after street and number" do
          person.postbox = "Postfach 10"
          expect(text).to eq <<~TEXT
            Top Leader
            Greatstreet 345
            Postfach 10
            3456 Greattown
          TEXT
        end
      else
        it "postbox is ignored" do
          person.postbox = "Postfach 10"
          expect(text).to eq <<~TEXT
            Top Leader
            Greatstreet 345
            3456 Greattown
          TEXT
        end
      end

      describe "company name" do
        it "ignores company_name when company flag is missing" do
          person.company_name = "Company LTD"
          expect(text).to eq <<~TEXT
            Top Leader
            Greatstreet 345
            3456 Greattown
          TEXT
        end

        it "ignores company flag when company_name is missing" do
          person.company = true
          expect(text).to eq <<~TEXT
            Top Leader
            Greatstreet 345
            3456 Greattown
          TEXT
        end

        if company == :replaces
          it "replaces name with company name when company_name and company flag are present" do
            person.company = true
            person.company_name = "Company LTD"
            expect(text).to eq <<~TEXT
              Company LTD
              Greatstreet 345
              3456 Greattown
            TEXT
          end
        elsif company == :adds
          it "places company name on top of name when company_name and company flag are present" do
            person.company = true
            person.company_name = "Company LTD"
            expect(text).to eq <<~TEXT
              Company LTD
              Top Leader
              Greatstreet 345
              3456 Greattown
            TEXT
          end
          it "ignores company name when company_name and company flag are present but name is identical" do
            person.company = true
            person.company_name = "Top Leader"
            expect(text).to eq <<~TEXT
              Top Leader
              Greatstreet 345
              3456 Greattown
            TEXT
          end
        elsif company == :ignored
          it "ignores company name when company_name and company flag are present" do
            person.company = true
            person.company_name = "Company LTD"
            expect(text).to eq <<~TEXT
              Top Leader
              Greatstreet 345
              3456 Greattown
            TEXT
          end
        end
      end
    end

    if label_handling
      context "label handling" do
        let(:label) { "Andere" }

        it "renders from person if not defined" do
          expect(text).to eq <<~TEXT
            Top Leader
            Greatstreet 345
            3456 Greattown
          TEXT
        end

        it "renders from additional address if label matches" do
          build_additional_address(label:, street: "Lagistrasse", housenumber: "12a", zip_code: 1080, town: "Jamestown")

          expect(text).to eq <<~TEXT
            Top Leader
            Lagistrasse 12a
            1080 Jamestown
          TEXT
        end

        if uses_additional_address_name
          it "reads additional name if set" do
            build_additional_address(label:, street: "Lagistrasse", housenumber: "12a", zip_code: 1080, town: "Jamestown", name: "Foo Bar", uses_contactable_name: false)
            expect(text).to eq <<~TEXT
              Foo Bar
              Lagistrasse 12a
              1080 Jamestown
            TEXT
          end
        end
      end
    end
  end

  describe "#for_letter" do
    subject(:text) { address.for_letter }

    it_behaves_like "common address behaviour", country_label: false, postbox: true, company: :adds
  end

  describe "#for_household_letter" do
    let(:members) { [person] }

    subject(:text) { address.for_household_letter(members) }

    describe "multiple members" do
      let(:members) { [people(:top_leader), people(:bottom_member)] }

      it "renders names, text and town with zip code" do
        expect(text).to eq <<~TEXT
          Top Leader, Bottom Member
          Greatstreet 345
          3456 Greattown
        TEXT
      end
    end

    it_behaves_like "common address behaviour", country_label: false, postbox: true, company: :ignored, uses_additional_address_name: false
  end

  describe "#for_invoice" do
    subject(:text) { address.for_invoice }

    let(:attrs) { {label: nil, street: "Lagistrasse", housenumber: "12a", zip_code: 1080, town: "Jamestown", invoices: true} }

    it_behaves_like "common address behaviour", country_label: false, postbox: false, company: :adds, label_handling: false

    it "uses invoice address if additional address with invoice flag exists" do
      build_additional_address(attrs)
      expect(text).to eq <<~TEXT
        Top Leader
        Lagistrasse 12a
        1080 Jamestown
      TEXT
    end

    it "uses address_care_of from additional address" do
      build_additional_address(attrs.merge(address_care_of: "c/o Finance"))
      expect(text).to eq <<~TEXT
        Top Leader
        c/o Finance
        Lagistrasse 12a
        1080 Jamestown
      TEXT
    end

    it "uses address_care_of from additional address" do
      build_additional_address(attrs.merge(address_care_of: "c/o Finance", name: "Foo Bar", uses_contactable_name: false))
      expect(text).to eq <<~TEXT
        Foo Bar
        c/o Finance
        Lagistrasse 12a
        1080 Jamestown
      TEXT
    end

    it "does not print blank address_care_of line" do
      build_additional_address(attrs.merge(address_care_of: "", name: "Foo Bar", uses_contactable_name: false))
      expect(text).to eq <<~TEXT
        Foo Bar
        Lagistrasse 12a
        1080 Jamestown
      TEXT
    end
  end

  describe "#for_pdf_label" do
    def text(name: person.to_s, nickname: false) = address.for_pdf_label(name, nickname)

    it "renders only address and town with zip code when passing nil name" do
      expect(text(name: nil)).to eq <<~TEXT
        Greatstreet 345
        3456 Greattown
      TEXT
    end

    it "renders nickname if set and passed" do
      person.nickname = "Toppy"
      expect(text(name: nil, nickname: true)).to eq <<~TEXT
        Toppy
        Greatstreet 345
        3456 Greattown
      TEXT
    end

    it_behaves_like "common address behaviour", country_label: true, postbox: false, company: :replaces
  end
end
