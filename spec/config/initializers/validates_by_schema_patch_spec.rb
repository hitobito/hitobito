# frozen_string_literal: true

#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

require "spec_helper"

describe ValidatesBySchema::IgnoreSequenceDefaultColumns do
  let(:connection) { ActiveRecord::Base.connection }

  let(:model) do
    Class.new(ActiveRecord::Base) do
      self.table_name = "validates_by_schema_patch_test"

      def self.name = "ValidatesBySchemaPatchTest"

      validates_by_schema
    end
  end

  before do
    connection.create_table :validates_by_schema_patch_test do |t|
      t.string :label, null: false
    end
    connection.execute("CREATE SEQUENCE validates_by_schema_patch_test_number_seq")
    connection.add_column :validates_by_schema_patch_test, :number, :bigint,
      null: false,
      default: -> { "nextval('validates_by_schema_patch_test_number_seq')" }
  end

  it "skips validations for not null columns with a sequence default" do
    expect(model.validators_on(:number)).to be_empty
  end

  it "keeps presence validation for other not null columns" do
    expect(model.validators_on(:label).map(&:kind)).to include(:presence)
  end

  it "lets the database assign the sequence value" do
    record = model.create!(label: "test")

    expect(record.reload.number).to eq(1)
  end
end
