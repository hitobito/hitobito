# frozen_string_literal: true

require "spec_helper"

describe Group::NestedSet do
  describe ".below_or_at_condition" do
    context "with integer values" do
      it "generates correct SQL condition" do
        result = Group.below_or_at_condition(5, 10)
        expect(result).to eq('"groups".lft >= 5 AND "groups".rgt <= 10')
      end

      it "accepts custom table name" do
        result = Group.below_or_at_condition(5, 10, "custom_table")
        expect(result).to eq("custom_table.lft >= 5 AND custom_table.rgt <= 10")
      end
    end

    context "with column references" do
      it "generates correct SQL condition for JOIN clauses" do
        result = Group.below_or_at_condition("other_table.lft", "other_table.rgt", "groups")
        expect(result).to eq("groups.lft >= other_table.lft AND groups.rgt <= other_table.rgt")
      end
    end
  end

  describe ".above_or_at_condition" do
    context "with integer values" do
      it "generates correct SQL condition" do
        result = Group.above_or_at_condition(5, 10)
        expect(result).to eq('"groups".lft <= 5 AND "groups".rgt >= 10')
      end

      it "accepts custom table name" do
        result = Group.above_or_at_condition(5, 10, "custom_table")
        expect(result).to eq("custom_table.lft <= 5 AND custom_table.rgt >= 10")
      end
    end

    context "with column references" do
      it "generates correct SQL condition for JOIN clauses" do
        result = Group.above_or_at_condition("other_table.lft", "other_table.rgt", "groups")
        expect(result).to eq("groups.lft <= other_table.lft AND groups.rgt >= other_table.rgt")
      end
    end
  end
end
