# frozen_string_literal: true

#  Copyright (c) 2023, CEVI Schweiz, Pfadibewegung Schweiz,
#  Jungwacht Blauring Schweiz, Pro Natura, Stiftung für junge Auslandschweizer.
#  This file is part of hitobito_youth and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_youth.

require "spec_helper"

describe People::Merger do
  let!(:person) { Fabricate(:person) }
  let!(:duplicate) { Fabricate(:person_with_address_and_phone) }
  let(:actor) { people(:top_leader) }
  let(:person_roles) { person.roles.with_deleted }

  let(:merger) { described_class.new(@source.reload, @target.reload, actor) }

  before do
    Group::BottomGroup::Member.create!(group: groups(:bottom_group_one_one),
      person: duplicate)
  end

  context "merge people" do
    it "migrates managers" do
      @source = duplicate
      @target = person

      source_manager = Fabricate(:person)
      target_manager = Fabricate(:person)

      @source.managers = [source_manager]
      @target.managers = [target_manager]

      expect do
        merger.merge!
      end.to change(Person, :count).by(-1)

      expect(person.managers).to match_array([source_manager, target_manager])
    end

    it "does not generate duplicate managers" do
      @source = duplicate
      @target = person

      manager = Fabricate(:person)

      @source.managers = [manager]
      @target.managers = [manager]

      expect do
        merger.merge!
      end.to change(Person, :count).by(-1)

      expect(person.managers.size).to eq(1)
      expect(person.managers.first).to eq(manager)
    end

    it "migrates manageds" do
      @source = duplicate
      @target = person

      source_managed = Fabricate(:person)
      target_managed = Fabricate(:person)

      @source.manageds = [source_managed]
      @target.manageds = [target_managed]

      expect do
        merger.merge!
      end.to change(Person, :count).by(-1)

      expect(person.manageds).to match_array([source_managed, target_managed])
    end

    it "does not generate duplicate manageds" do
      @source = duplicate
      @target = person

      managed = Fabricate(:person)

      @source.manageds = [managed]
      @target.manageds = [managed]

      expect do
        merger.merge!
      end.to change(Person, :count).by(-1)

      expect(person.manageds.size).to eq(1)
      expect(person.manageds.first).to eq(managed)
    end
  end
end
