#  Copyright (c) 2012-2024, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe SearchStrategies::GroupSearch do
  before do
    @bl_leader = Fabricate(Group::BottomLayer::Leader.name.to_sym, group: groups(:bottom_layer_one)).person
  end

  describe "#search_fulltext" do
    context "as leader" do
      let(:user) { @bl_leader }

      it "finds groups" do
        result = search_class(groups(:bottom_layer_one).to_s[0..5]).search_fulltext

        expect(result).to include(groups(:bottom_layer_one))
      end

      # infix search wasn't implemented
      xit "finds groups with Infix term" do
        result = search_class(groups(:bottom_layer_one).to_s[1..5]).search_fulltext

        expect(result).to include(groups(:bottom_layer_one))
      end

      context "without any params" do
        it "returns nothing" do
          result = search_class.search_fulltext

          expect(result).to eq([])
        end
      end
    end

    context "as unprivileged person" do
      let(:user) { Fabricate(:person) }

      it "finds groups" do
        result = search_class(groups(:bottom_layer_one).to_s[0..5]).search_fulltext

        expect(result).to include(groups(:bottom_layer_one))
      end
    end
  end

  def search_class(term = nil, page = nil)
    described_class.new(user, term, page)
  end
end
