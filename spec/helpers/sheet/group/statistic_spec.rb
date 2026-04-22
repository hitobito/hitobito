# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Wanderwege. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

require "spec_helper"

describe Sheet::Group::Statistic do
  let(:group) { groups(:bottom_layer_one) }

  let(:extra_stat) do
    Class.new(Group::Statistics::Base) do
      self.key = :extra_stat
      self.layer_only = false
    end
  end

  around do |example|
    original = Group::Statistics::Registry.statistics.dup
    Group::Statistics::Registry.register(extra_stat)
    example.run
    Group::Statistics::Registry.statistics.replace(original)
  end

  # The sheet receives `self` as view context; stub the controller method it calls
  let(:controller) { double(:controller, statistic_key: :people).as_null_object }

  let(:sheet) do
    @group = group
    Sheet::Group::Statistic.new(self)
  end

  describe "tabs" do
    it "builds one tab per available statistic" do
      available = Group::Statistics::Registry.available_for(group)
      expect(sheet.class.tabs.size).to eq available.size
    end

    it "creates a tab for each registered statistic key" do
      keys = sheet.class.tabs.map(&:params)
      expect(keys).to include(:people, :extra_stat)
    end
  end

  describe "#path_args" do
    it "returns the group as path argument" do
      expect(sheet.path_args).to eq [group]
    end
  end

  describe "active tab" do
    it "marks the people tab as active when statistic_key is :people" do
      allow(controller).to receive(:statistic_key).and_return(:people)
      expect(sheet.active_tab.params).to eq :people
    end

    it "does not select the people tab as the active one" do
      allow(controller).to receive(:statistic_key).and_return(:extra_stat)
      expect(sheet.active_tab.params).to eq :extra_stat
    end
  end
end
