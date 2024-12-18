# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

require "spec_helper"

describe Export::Tabular::Base do
  let(:tabular) do
    Class.new(Export::Tabular::Base) do
      self.model_class = ::Person

      def attributes = %i[first_name]
    end
  end

  subject(:instance) { tabular.new(scope) }

  describe "#attribute_labels" do
    let(:scope) { Person.where(id: people(:top_leader)) }

    it "gets attribute labels from instance methods" do
      instance.define_singleton_method(:first_name_label) { "Taufname" }
      expect(instance.attribute_labels).to eq(first_name: "Taufname")
    end

    it "falls back to human attribute name if no label method is present" do
      expect(instance).not_to respond_to("first_name_label")
      expect(instance.attribute_labels).to eq(first_name: "Vorname")
    end
  end

  describe "#data_rows" do
    def iterate(scope)
      [].tap do |list|
        instance = tabular.new(scope)
        yield instance if block_given?

        instance.data_rows do |first_name|
          list << first_name
        end
      end.flatten
    end

    it "yields in scope order" do
      expect(iterate(Person.order(first_name: :asc))).to eq ["Bottom", "Top", nil]
      expect(iterate(Person.order(first_name: :desc))).to eq [nil, "Top", "Bottom"]
    end

    it "iterates with limit and offset" do
      scope = Person.all
      expect(scope).to receive(:offset).with(0).and_call_original
      expect(scope).to receive(:limit).with(1000).and_call_original
      iterate(scope)
    end

    it "iterates respecting batch_size" do
      scope = Person.all
      expect(scope).to receive(:offset).with(0).once.and_call_original
      expect(scope).to receive(:offset).with(2).once.and_call_original
      iterate(scope) do |instance|
        instance.batch_size = 2
      end
    end

    it "iterates over array with each" do
      array = Person.all.to_a
      expect(array).to receive(:each).once.and_call_original
      iterate(array)
    end
  end
end
