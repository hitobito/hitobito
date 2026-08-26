# frozen_string_literal: true

#  Copyright (c) 2012-2026, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

# Exercises ContactAccount#assert_category_unique_per_contactable against a
# concrete contact-account model/contactable pairing. Included from
# spec/models/concerns/contactable_spec.rb. Kept top-level (not nested inside
# the describe block below) since shared_examples defined inside a describe
# block are only reachable from within that same describe's hierarchy --
# nesting it here would make it invisible to contactable_spec.rb's
# `it_behaves_like` calls.
#
# opts:
#   factory:               fabricator name, e.g. :phone_number
#   factory_attrs:         attrs (besides contactable/category) needed to build a valid record
#   contactable:           -> { ... } returning the contactable to build entries on
#   other_contactable:     -> { ... } returning a different contactable of the same type
#   unique_category:       fixture key of a unique_per_contactable: true category
#   other_unique_category: fixture key of a different unique_per_contactable: true category
#   non_unique_category:   fixture key of a unique_per_contactable: false category
shared_examples "enforces category uniqueness per contactable" do |opts|
  let(:factory) { opts.fetch(:factory) }
  let(:association) { factory.to_s.pluralize.to_sym }
  let(:factory_attrs) { opts.fetch(:factory_attrs) }
  let(:contactable) { instance_exec(&opts.fetch(:contactable)) }
  let(:other_contactable) { instance_exec(&opts.fetch(:other_contactable)) }
  let(:unique_category) { contact_account_categories(opts.fetch(:unique_category)) }
  let(:other_unique_category) { contact_account_categories(opts.fetch(:other_unique_category)) }
  let(:non_unique_category) { contact_account_categories(opts.fetch(:non_unique_category)) }

  it "is invalid when other entry already uses unique category" do
    contactable.public_send(association).create!(category: unique_category, **factory_attrs)
    other = contactable.public_send(association).build(category: unique_category, **factory_attrs)

    expect(other).not_to be_valid
    expect(other.errors[:category]).to be_present
    expect(other.errors.full_messages).to eq ["Kategorie #{unique_category} ist bereits vergeben"]
  end

  it "is valid when the other entry uses a another unique category" do
    Fabricate(factory, contactable:, category: unique_category, **factory_attrs)
    other = Fabricate.build(factory, contactable:, category: other_unique_category,
      **factory_attrs)

    expect(other).to be_valid
  end

  it "is valid to use a category that is not unique_per_contactable more than once" do
    Fabricate(factory, contactable:, category: non_unique_category, **factory_attrs)
    other = Fabricate.build(factory, contactable:, category: non_unique_category,
      **factory_attrs)

    expect(other).to be_valid
  end

  it "is valid when a different contactable uses the unique category" do
    Fabricate(factory, contactable:, category: unique_category, **factory_attrs)
    other = Fabricate.build(factory, contactable: other_contactable, category: unique_category,
      **factory_attrs)

    expect(other).to be_valid
  end

  it "allows replacing an entry with a new one under the same category in one save" do
    existing = contactable.public_send(association).create!(category: unique_category, **factory_attrs)
    contactable.public_send(association).build(category: unique_category, **factory_attrs)
    existing.mark_for_destruction

    expect(contactable.valid?).to eq true
  end

  it "does not leave the contactable's association cached as empty afterwards" do
    # Regression test: the uniqueness check reads contactable.public_send(association),
    # which loads and caches that association on the contactable as a side effect. Since
    # this runs pre-save, that read used to find no siblings (this record doesn't exist in
    # the DB yet) and leave that now-stale, empty cache behind for the rest of the
    # contactable's lifetime in memory -- hiding entries created this way (as opposed to
    # contactable.public_send(association).create!(...), which keeps the cache in sync
    # itself) from any later read.
    Fabricate(factory, contactable:, category: unique_category, **factory_attrs)

    expect(contactable.public_send(association).count).to eq 1
  end
end

shared_examples "fixing common autocomplete issues" do |column|
  subject(:model) { described_class.new(street:, housenumber:, zip_code:, town:) }

  relevant_attrs = [:street, :housenumber, :zip_code, :town]
  relevant_attrs.each do |attr|
    it "maintains valid #{column} value" do
      model.send(:"#{column}=", "3000")
      model.valid?
      expect(model.send(column)).to eq "3000"
    end

    it "clears #{column} if it equals #{attr} value" do
      model.send(:"#{column}=", send(attr))
      model.valid?
      expect(model.send(column)).to be_nil
    end

    it "clears #{column} if it equals 'street housenumber' value" do
      model.send(:"#{column}=", "#{street} #{housenumber}")
      model.valid?
      expect(model.send(column)).to be_nil
    end

    it "does not clear #{column} if it only contains #{attr} value" do
      model.send(:"#{column}=", "pre #{send(attr)} post")
      model.valid?
      expect(model.send(column)).to eq "pre #{send(attr)} post"
    end
  end
end
