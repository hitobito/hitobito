#  Copyright (c) 2012-2024, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe SearchStrategies::InvoiceSearch do

  before do
    @bl_member = Fabricate(Group::BottomLayer::Member.name.to_sym, group: groups(:bottom_layer_one)).person
  end

  describe "#search_fulltext" do
    context "with finance group permission" do
      let(:user) { @bl_member }

      it "finds invoices" do
        result = search_class(invoices(:invoice).to_s[0..5]).search_fulltext

        expect(result).to include(invoices(:invoice))
      end

      it "finds invoices via invoice item" do
        result = search_class("pens").search_fulltext

        expect(result).to include(invoices(:invoice))
      end

      # infix search wasn't implemented
      xit "finds invoices with Infix term" do
        result = search_class(invoices(:invoice).to_s[1..5]).search_fulltext

        expect(result).to include(invoices(:invoice))
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

      it "does not find invoices" do
        result = search_class(invoices(:invoice).to_s[0..5]).search_fulltext

        expect(result).not_to include(invoices(:invoice))
      end
    end

  end

  def search_class(term = nil, page = nil)
    described_class.new(user, term, page)
  end

end
