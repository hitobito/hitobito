#  Copyright (c) 2012-2024, Schweizer Blasmusikverband. This file is part of
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
      end

      context "match" do
        let(:constraint) { "match" }
        let(:value) { "Abend" }

        it "returns people with matching attribute" do
          expect(entries).to match_array([@raclette, @fondue])
        end
      end

      context "not_match" do
        let(:constraint) { "not_match" }
        let(:value) { "Abend" }

        it "returns people with not matching attribute" do
          expect(entries).to match_array([@pizza])
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
  end
end
