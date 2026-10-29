#  Copyright (c) 2012-2026, Schweizer Blasmusikverband. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Events::Filter::Attributes do
  let(:user) { people(:top_leader) }
  let(:group) { groups(:top_group) }
  let(:key) { "description" }
  let(:constraint) { "match" }
  let(:value) { "" }
  let(:range) { "deep" }

  let(:list_filter) do
    ::Events::Filter::GroupList.new(
      group,
      user,
      range: range,
      type: nil,
      year: 2012,
      filters: {attributes: filters}
    )
  end

  let(:filters) do
    {
      "1234567890123": {
        key: key,
        constraint: constraint,
        value: value
      }
    }
  end

  let(:entries) { list_filter.entries }

  context "filtering" do
    before do
      @raclette = Fabricate(:event, groups: [group], description: "Raclette Abend")
      @pizza = Fabricate(:event, groups: [group], description: "Pizza Nami")
      @fondue = Fabricate(:event, groups: [group], description: "Fondue Abend")
    end

    context "no filter" do
      it "contains all existing entries" do
        expect(entries.size).to eq(list_filter.all_count)
      end
    end

    context "translated attribute" do
      context "equal" do
        let(:constraint) { "equal" }

        context "with exact value" do
          let(:value) { "Fondue Abend" }

          it "returns entries" do
            expect(entries).to match_array([@fondue])
          end
        end

        context "with partial value" do
          let(:value) { "Fondue" }

          it "returns nothing" do
            expect(entries.size).to be_zero
          end
        end

        context "with different case" do
          let(:value) { "fondue ABEND" }

          it "ignores the case" do
            expect(entries).to match_array([@fondue])
          end
        end
      end

      context "match" do
        let(:constraint) { "match" }
        let(:value) { "Abend" }

        it "returns people with matching attribute" do
          expect(entries).to match_array([@raclette, @fondue])
        end

        context "with different case" do
          let(:value) { "aBEND" }

          it "ignores the case" do
            expect(entries).to match_array([@raclette, @fondue])
          end
        end
      end

      context "not_match" do
        let(:constraint) { "not_match" }
        let(:value) { "Abend" }

        it "returns events with not matching attribute" do
          expect(entries).to include(@pizza)
          expect(entries).not_to include(@raclette, @fondue)
        end

        it "returns events without description" do
          without_description = Fabricate(:event, groups: [group])
          expect(entries).to include(without_description)
        end

        it "excludes events with matching description in another language" do
          I18n.with_locale(:fr) { @pizza.update!(description: "Pizza Abend") }
          expect(entries).not_to include(@pizza)
        end

        it "excludes events with matching description and another language without description" do
          I18n.with_locale(:fr) { @raclette.update!(name: "Raclette") }
          expect(entries).not_to include(@raclette)
        end

        context "with different case" do
          let(:value) { "aBEND" }

          it "ignores the case" do
            expect(entries).to include(@pizza)
            expect(entries).not_to include(@raclette, @fondue)
          end
        end
      end

      context "blank" do
        let(:constraint) { "blank" }
        let(:value) { "" }

        it "returns people with blank attribute" do
          @raclette.update!(description: nil)
          expect(entries).to match_array([@raclette])
        end
      end
    end

    context "column attribute" do
      let(:key) { "location" }
      let(:value) { "bern" }

      before do
        @raclette.update!(location: "Bern")
        @pizza.update!(location: "Zürich")
        @fondue.update!(location: nil)
      end

      context "match" do
        let(:constraint) { "match" }

        it "ignores the case" do
          expect(entries).to match_array([@raclette])
        end
      end

      context "not_match" do
        let(:constraint) { "not_match" }

        it "returns events with other or without location" do
          expect(entries).to include(@pizza, @fondue)
          expect(entries).not_to include(@raclette)
        end
      end
    end
  end
end
