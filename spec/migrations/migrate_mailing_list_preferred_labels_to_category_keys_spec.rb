# frozen_string_literal: true

#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "rails_helper"
require_relative "../../db/migrate/20261004090000_migrate_mailing_list_preferred_labels_to_category_keys"

RSpec.describe MigrateMailingListPreferredLabelsToCategoryKeys, type: :migration do
  subject(:migration) { described_class.new }

  let(:list) { Fabricate(:mailing_list, group: groups(:top_layer)) }

  around do |example|
    ActiveRecord::Migration.verbose = false
    example.run
    ActiveRecord::Migration.verbose = true
  end

  def run = migration.up

  it "leaves a value that already is a category key untouched" do
    list.update_column(:preferred_labels, %w[work])

    run

    expect(list.reload.preferred_labels).to eq %w[work]
  end

  it "resolves a translated category name to its key" do
    list.update_column(:preferred_labels, %w[Arbeit])

    run

    expect(list.reload.preferred_labels).to eq %w[work]
  end

  it "resolves a legacy label from LABEL_KEY_MAPPING to its key" do
    list.update_column(:preferred_labels, %w[geschäft])

    run

    expect(list.reload.preferred_labels).to eq %w[work]
  end

  it "keeps a value that resolves to nothing" do
    list.update_column(:preferred_labels, %w[some_custom_label])

    run

    expect(list.reload.preferred_labels).to eq %w[some_custom_label]
  end

  it "does not touch lists without preferred_labels" do
    list.update_column(:preferred_labels, [])

    run

    expect(list.reload.preferred_labels).to eq []
  end
end
