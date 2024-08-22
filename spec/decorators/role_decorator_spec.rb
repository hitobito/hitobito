# frozen_string_literal: true

#
# Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
# hitobito_sac_cas and licensed under the Affero General Public License version 3
# or later. See the COPYING file at the top-level directory or at
# https://github.com/hitobito/hitobito

require "spec_helper"

describe RoleDecorator, :draper_with_helpers do
  let(:role) { roles(:top_leader) }
  let(:today) { Time.zone.local(2023, 11, 13) }

  let(:decorator) { described_class.new(role) }

  around do |example|
    travel_to(today.midnight) { example.run }
  end

  context "for_aside" do
    let(:node) { Capybara::Node::Simple.new(decorator.for_aside) }
    let(:decorated_name) { decorator.for_aside }

    it "includes bis" do
      role.end_on = Time.zone.local(2023, 12, 12)

      formatted_name = "<strong>Leader</strong>&nbsp;(bis 12.12.2023)"

      expect(decorated_name).to eq(formatted_name)
    end

    it "includes label" do
      role.label = "42"
      formatted_name = "<strong>Leader</strong>&nbsp;(42)"

      expect(decorated_name).to eq(formatted_name)
    end
  end

  context "for_history" do
    let(:node) { Capybara::Node::Simple.new(decorator.for_history) }
    let(:decorated_name) { decorator.for_history }

    it "role#to_s without strong tag and without triangle" do
      expect(node).not_to have_css("strong", text: role.to_s)
      expect(node).not_to have_css("i.fas.fa-exclamation-triangle")
    end

    it "never includes bis and is not bold" do
      role.end_on = Time.zone.local(2023, 12, 12)

      expect(decorated_name).to eq("Leader")
    end

    it "includes label and is not bold" do
      role.label = "42"
      formatted_name = "Leader&nbsp;(42)"

      expect(decorated_name).to eq(formatted_name)
    end
  end
end
