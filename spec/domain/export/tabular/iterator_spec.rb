# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of hitobito and licensed under the
#  Affero General Public License version 3 or later. See the COPYING file at the top-level directory
#  or at https://github.com/hitobito/hitobito.

require "spec_helper"

describe Export::Tabular::Iterator do
  subject(:iterator) { described_class.new(list, batch_size) }

  context "with a plain array" do
    let(:list) { [1, 2, 3] }
    let(:batch_size) { 2 }

    it "delegates directly to Array#each without batching" do
      expect(list).to receive(:each).once.and_call_original
      expect { |b| iterator.each(&b) }.to yield_successive_args(1, 2, 3)
    end
  end

  context "with an ActiveRecord::Relation" do
    let!(:people) do
      Array.new(3) { |i| Fabricate(:person, first_name: "Person#{i}") }
    end
    let(:list) { Person.where(id: people.map(&:id)).order(:first_name) }

    context "batch_size smaller than the total count" do
      let(:batch_size) { 2 }

      it "yields all records in order across multiple batches" do
        expect { |b| iterator.each(&b) }.to yield_successive_args(*people)
      end

      it "fetches successive offsets until a short batch is returned" do
        expect(list).to receive(:offset).with(0).once.and_call_original
        expect(list).to receive(:offset).with(2).once.and_call_original
        iterator.each { |_person| }
      end
    end

    context "batch_size that evenly divides the total count" do
      let(:batch_size) { 1 }

      it "issues one extra query to detect the end of the relation" do
        queries = []
        subscription = ActiveSupport::Notifications.subscribe("sql.active_record") do |*, payload|
          queries << payload[:binds].last(2).map(&:value) if payload[:sql].include?(%("people"."id"))
        end

        begin
          iterator.each { |_person| }
        ensure
          ActiveSupport::Notifications.unsubscribe(subscription)
        end

        expect(queries).to eq [
          [1, 0], # LIMIT 1 OFFSET 0
          [1, 1], # LIMIT 1 OFFSET 1
          [1, 2], # LIMIT 1 OFFSET 2
          [1, 3]  # LIMIT 1 OFFSET 3 -- the extra query that detects the end
        ]
      end
    end

    context "batch_size larger than the total count" do
      let(:batch_size) { 1000 }

      it "yields all records in a single batch" do
        expect(list).to receive(:limit).with(1000).once.and_call_original
        expect(list).to receive(:offset).with(0).once.and_call_original
        expect { |b| iterator.each(&b) }.to yield_successive_args(*people)
      end
    end

    context "empty relation" do
      let(:list) { Person.where(id: -1) }
      let(:batch_size) { 1000 }

      it "yields nothing" do
        expect { |b| iterator.each(&b) }.not_to yield_control
      end
    end

    context "relation with a pre-existing limit" do
      let(:list) { Person.where(id: people.map(&:id)).order(:first_name).limit(1) }
      let(:batch_size) { 1000 }

      it "does not batch and respects the original limit" do
        expect(list).not_to receive(:offset)
        expect { |b| iterator.each(&b) }.to yield_successive_args(people.first)
      end
    end

    context "without a block" do
      let(:batch_size) { 2 }

      it "returns an Enumerator that performs the same batching when consumed" do
        enum = iterator.each

        expect(enum).to be_a(Enumerator)
        expect(enum.to_a).to eq people
      end

      it "supports Enumerable methods such as #map" do
        expect(iterator.map(&:first_name)).to eq people.map(&:first_name)
      end

      it "supports Enumerable methods such as #count" do
        expect(iterator.count).to eq 3
      end
    end
  end
end
