# frozen_string_literal: true

#  Copyright (c) 2026, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Group::Statistics::Base do
  let(:layer) { groups(:top_layer) }
  let(:non_layer) { groups(:top_group) }

  # Minimal test subclass
  let(:test_class) do
    Class.new(Group::Statistics::Base) do
      self.key = :test
      self.permitted_params = [:foo, :bar]
    end
  end

  describe ".available_for?" do
    context "with layer_only: true (default)" do
      it "is true for a layer group" do
        expect(test_class.available_for?(layer)).to be true
      end

      it "is false for a non-layer group" do
        expect(test_class.available_for?(non_layer)).to be false
      end
    end

    context "with layer_only: false" do
      before { test_class.layer_only = false }

      it "is true for any group" do
        expect(test_class.available_for?(non_layer)).to be true
      end
    end

    context "with group_types restriction" do
      before { test_class.group_types = [Group::TopLayer] }

      it "is true when group matches type" do
        expect(test_class.available_for?(layer)).to be true
      end

      it "is false when group does not match type" do
        other_layer = groups(:bottom_layer_one)
        expect(test_class.available_for?(other_layer)).to be false
      end
    end
  end

  describe ".label_key" do
    it "returns the i18n key for the title" do
      expect(test_class.label_key).to eq "group.statistics.test.title"
    end
  end

  describe "#initialize" do
    it "raises when layer_only and group is not a layer" do
      expect { test_class.new(non_layer) }.to raise_error(ArgumentError, /should be a layer/)
    end

    it "accepts plain hash as params" do
      instance = test_class.new(layer, foo: "bar")
      expect(instance.filter_params[:foo]).to eq "bar"
    end

    it "accepts ActionController::Parameters as params" do
      params = ActionController::Parameters.new(foo: "bar", baz: "ignored")
      instance = test_class.new(layer, params)
      expect(instance.filter_params[:foo]).to eq "bar"
      expect(instance.filter_params).not_to have_key(:baz)
    end

    it "defaults to empty params" do
      instance = test_class.new(layer)
      expect(instance.filter_params).to eq({})
    end
  end

  describe "#filter_params" do
    it "only includes permitted params" do
      instance = test_class.new(layer, foo: "1", bar: "2", secret: "3")
      expect(instance.filter_params.keys).to contain_exactly(:foo, :bar)
    end
  end

  describe "#partial_path" do
    it "returns the view partial path" do
      instance = test_class.new(layer)
      expect(instance.partial_path).to eq "group/statistics/test"
    end
  end

  describe "validations" do
    it "is valid with no validations defined" do
      expect(test_class.new(layer)).to be_valid
    end

    it "exposes an errors object" do
      expect(test_class.new(layer).errors).to be_a(ActiveModel::Errors)
    end

    it "supports validate in subclasses" do
      klass = Class.new(Group::Statistics::Base) do
        self.key = :with_validation
        validate { errors.add(:base, "always invalid") }
      end
      instance = klass.new(layer)
      expect(instance).not_to be_valid
      expect(instance.errors[:base]).to include("always invalid")
    end
  end
end
