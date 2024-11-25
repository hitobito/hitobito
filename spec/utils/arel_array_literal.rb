# frozen_string_literal: true

#  Copyright (c) 2024. This file is part of
#  hitobito_cevi and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_cevi.

require "spec_helper"

describe ArelArrayLiteral do
  let(:items) { [] }
  subject(:array_literal) { described_class.new(items) }

  describe "#to_sql" do
    subject(:to_sql) { array_literal.to_sql }
    context "with ids" do
      let(:items) { [1, 2, "test", true, nil] }
      it "evaluates to postgres ARRAY[] literal" do
        is_expected.to eq("ARRAY[1,2,'test',TRUE,NULL]")
      end
    end
  end

  describe "#eql" do
    it "is equal when items are equal" do
      expect(described_class.new([1,2])).to eql(described_class.new([1,2]))
    end

    it "is not equal when items are equal" do
      expect(described_class.new([1,2])).not_to eql(described_class.new([3,4]))
    end
  end
end
