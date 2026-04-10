# frozen_string_literal: true

require "spec_helper"

describe Group::NestedSet do
  describe ".below_or_at_condition" do
    context "with integer values" do
      it "generates correct SQL condition" do
        result = Group.below_or_at_condition(5, 10)
        expect(result).to eq('"groups".lft >= 5 AND "groups".rgt <= 10')
      end

      it "quotes custom table name" do
        result = Group.below_or_at_condition(5, 10, "custom_table")
        expect(result).to eq('"custom_table".lft >= 5 AND "custom_table".rgt <= 10')
      end
    end

    context "with column references" do
      it "generates correct SQL condition for JOIN clauses" do
        result = Group.below_or_at_condition("other_table.lft", "other_table.rgt", "groups")
        expect(result).to eq('"groups".lft >= other_table.lft AND "groups".rgt <= other_table.rgt')
      end

      it "accepts ? bind-parameter placeholders" do
        result = Group.below_or_at_condition("?", "?")
        expect(result).to eq('"groups".lft >= ? AND "groups".rgt <= ?')
      end
    end

    context "with unsafe input" do
      it "raises ArgumentError for unsafe lft" do
        expect { Group.below_or_at_condition("1 OR 1=1", 10) }.to raise_error(ArgumentError, /Unsafe/)
      end

      it "raises ArgumentError for unsafe rgt" do
        expect { Group.below_or_at_condition(5, "10; DROP TABLE groups--") }.to raise_error(ArgumentError, /Unsafe/)
      end
    end
  end

  describe ".above_or_at_condition" do
    context "with integer values" do
      it "generates correct SQL condition" do
        result = Group.above_or_at_condition(5, 10)
        expect(result).to eq('"groups".lft <= 5 AND "groups".rgt >= 10')
      end

      it "quotes custom table name" do
        result = Group.above_or_at_condition(5, 10, "custom_table")
        expect(result).to eq('"custom_table".lft <= 5 AND "custom_table".rgt >= 10')
      end
    end

    context "with column references" do
      it "generates correct SQL condition for JOIN clauses" do
        result = Group.above_or_at_condition("other_table.lft", "other_table.rgt", "groups")
        expect(result).to eq('"groups".lft <= other_table.lft AND "groups".rgt >= other_table.rgt')
      end

      it "accepts ? bind-parameter placeholders" do
        result = Group.above_or_at_condition("?", "?")
        expect(result).to eq('"groups".lft <= ? AND "groups".rgt >= ?')
      end
    end

    context "with unsafe input" do
      it "raises ArgumentError for unsafe lft" do
        expect { Group.above_or_at_condition("1 OR 1=1", 10) }.to raise_error(ArgumentError, /Unsafe/)
      end

      it "raises ArgumentError for unsafe rgt" do
        expect { Group.above_or_at_condition(5, "10; DROP TABLE groups--") }.to raise_error(ArgumentError, /Unsafe/)
      end
    end
  end
end
