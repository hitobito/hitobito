# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe "TomSelect Stimulus Controller", js: true do
  before do
    stub_const("TomSelectController", Class.new(ActionController::Base) { # rubocop:disable Rails/ApplicationController
      include Webpacker::Helper
      include ActionView::Helpers::AssetTagHelper

      helper_method :tom_select_tag

      def new
        # The HTML for your form element
        render inline: <<~HTML
          <head>
            #{stylesheet_pack_tag "application", media: "screen", "data-turbo-track": true}
            #{javascript_pack_tag "application", "data-turbo-track": true}
            <!-- add fake inline favicon to avoid 404 error -->
            <link rel="icon" href="data:image/x-icon;," type="image/x-icon">
          </head>
          <body>
            <h1>TomSelect Test</h1>
            #{tom_select_tag}
          </body>
        HTML
      end

      def tom_select_tag
        id = "tom-select-#{Fabrication::Sequencer.sequence(:tom_select)}"
        options = 10.times.map { |i| "<option value=\"#{i}\">Option #{i}</option>" }.join("\n")
        data = tom_select_params.map { |k, v| "#{k}=\"#{CGI.escapeHTML(v)}\"" }.join(" ")
        <<~HTML
          <select name="#{id}" id="#{id}" data-controller="tom-select" #{data}>
            #{options}
          </select>
        HTML
      end

      def tom_select_params = params.permit!.to_h.select { |k, _| k =~ /^data-tom-select-/ }
    })

    draw_test_routes do
      get "/tom_select", to: "tom_select#new"
    end
  end

  it "initializes tom_select" do
    visit "/tom_select"

    # Check that the original select is present (and likely hidden by TomSelect)
    expect(page).to have_selector("select[data-controller='tom-select']", visible: false)

    # Check that TomSelect's wrapper has been created
    expect(page).to have_selector(".ts-wrapper", visible: true)

    expect(page).to have_selector(".ts-control .item", text: "Option 0")

    # Interact with TomSelect
    find(".ts-control").click
    expect(page).to have_selector(".ts-dropdown .option", text: "Option 0")
  end

  context "Stimulus Values Configuration" do
    context "options" do
      it "renders custom description" do
        options = 5.times.map do |i|
          {id: i, label: "Custom Option #{i}", description: "Description #{i}"}
        end
        visit "/tom_select?data-tom-select-options-value=#{ERB::Util.url_encode(options.to_json)}&" \
          "data-tom-select-selected-value=[2]"

        expect(page).to have_selector(".ts-wrapper", visible: true)

        expect(page).to have_selector(".ts-control .item", text: "Custom Option 2")

        find(".ts-control").click
        expect(page).to have_selector(".ts-dropdown .option", text: "Custom Option 0")
        expect(page).to have_selector(".ts-dropdown .option .muted", text: "Description 0")
        expect(page).to have_selector(".ts-dropdown .option", count: 5)
      end
    end

    context "optgroups" do
      it "renders options in groups" do
        options = 5.times.map do |i|
          {id: i, label: "Custom Option #{i}", group: "group#{(i % 3) + 1}"}
        end
        optgroups = [
          {value: "group1", label: "Group 1"},
          {value: "group2", label: "Group 2"},
          {value: "group3", label: "Group 3"}
        ]
        visit "/tom_select?data-tom-select-options-value=#{ERB::Util.url_encode(options.to_json)}&" \
          "data-tom-select-optgroups-value=#{ERB::Util.url_encode(optgroups.to_json)}"

        expect(page).to have_selector(".ts-wrapper", visible: true)

        find(".ts-control").click
        expect(page).to have_selector(".ts-dropdown .optgroup-header", text: "Group 1")
        expect(page).to have_selector(".ts-dropdown [data-group='group1'] .option", text: "Custom Option 0")
        expect(page).to have_selector(".ts-dropdown [data-group='group1'] .option", text: "Custom Option 3")
        expect(page).to have_selector(".ts-dropdown [data-group='group2'] .option", text: "Custom Option 1")
        expect(page).to have_selector(".ts-dropdown .option", count: 5)
      end

      it "renders customized header" do
        options = 5.times.map do |i|
          {id: i, label: "Custom Option #{i}", group: "group#{(i % 3) + 1}"}
        end
        optgroups = [
          {value: "group1", label: "Group 1"},
          {value: "group2", label: "Group 2"},
          {value: "group3", label: "Group 3"}
        ]
        visit "/tom_select?data-tom-select-options-value=#{ERB::Util.url_encode(options.to_json)}&" \
          "data-tom-select-optgroups-value=#{ERB::Util.url_encode(optgroups.to_json)}&" \
          "data-tom-select-optgroups-header-value=return function(data) { return `<h1>${data.label}</h1>` }"

        expect(page).to have_selector(".ts-wrapper", visible: true)

        find(".ts-control").click
        expect(page).not_to have_selector(".ts-dropdown .optgroup-header", text: "Group 1")
        expect(page).to have_selector(".ts-dropdown h1", text: "Group 1")
        expect(page).to have_selector(".ts-dropdown [data-group='group1'] .option", text: "Custom Option 0")
      end
    end

    context "max_options" do
      it "when missing it has no limit" do
        visit "/tom_select"

        expect(page).to have_no_css("select[data-tom-select-max-options-value]", visible: false)

        find(".ts-control").click
        expect(page).to have_selector(".ts-dropdown .option", text: "Option 0")
        expect(page).to have_selector(".ts-dropdown .option", text: "Option 9")
        expect(page).to have_selector(".ts-dropdown .option", count: 10)
      end

      it "respects max_options value" do
        visit "/tom_select?data-tom-select-max-options-value=5"

        expect(page).to have_css("select[data-tom-select-max-options-value='5']", visible: false)

        find(".ts-control").click
        expect(page).to have_selector(".ts-dropdown .option", text: "Option 0")
        expect(page).to have_selector(".ts-dropdown .option", text: "Option 4")
        expect(page).to have_no_selector(".ts-dropdown .option", text: "Option 5")
        expect(page).to have_selector(".ts-dropdown .option", count: 5)
      end
    end
  end
end
