# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Wanderwege. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

require "spec_helper"

describe "group/statistics/show.html.haml" do
  let(:group) { groups(:bottom_layer_one) }
  let(:dom) { Capybara::Node::Simple.new(@rendered) }

  let(:statistic_class) do
    Class.new(Group::Statistics::Base) do
      self.key = :test_stat
      def self.name = "Group::Statistics::TestStat"
    end
  end

  let(:statistic) { statistic_class.new(group) }

  before do
    assign(:group, group)
    assign(:statistic, statistic)
    stub_template "group/statistics/_test_stat.html.haml" => "<div id='stat-content'>statistic content</div>"
    allow(view).to receive(:title)
  end

  context "without errors" do
    before { render }

    it "does not render error messages" do
      expect(dom).not_to have_selector("#error_explanation")
    end

    it "renders the statistic partial" do
      expect(dom).to have_selector("#stat-content", text: "statistic content")
    end
  end

  context "with errors on the statistic" do
    before do
      statistic.errors.add(:base, "something went wrong")
      render
    end

    it "renders the error explanation block" do
      expect(dom).to have_selector("#error_explanation")
    end

    it "shows the error message" do
      expect(dom).to have_text("something went wrong")
    end

    it "still renders the statistic partial" do
      expect(dom).to have_selector("#stat-content")
    end
  end

  context "with multiple errors" do
    before do
      statistic.errors.add(:base, "first error")
      statistic.errors.add(:base, "second error")
      render
    end

    it "lists all error messages" do
      expect(dom).to have_selector("#error_explanation li", count: 2)
    end
  end
end
