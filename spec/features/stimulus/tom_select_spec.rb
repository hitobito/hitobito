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
        <<~HTML
          <select name="#{id}" id="#{id}" data-controller="tom-select"
            #{tom_select_params.map { |k, v| "#{k}=\"#{v}\"" }.join(" ")}>
            #{1000.times.map { |i| "<option value=\"#{i}\">Option #{i}</option>" }.join("\n")}
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

    # Interact with TomSelect
    find(".ts-control").click
    expect(page).to have_selector(".ts-dropdown .option", text: "Option 0")
  end

  describe "Stimulus Values Configuration" do
    describe "max_options" do
      it "when missing it has no limit" do
        visit "/tom_select"

        expect(page).to have_no_css("select[data-tom-select-max-options-value]", visible: false)

        find(".ts-control").click
        expect(page).to have_selector(".ts-dropdown .option", text: "Option 0")
        expect(page).to have_selector(".ts-dropdown .option", text: "Option 999")
        expect(page).to have_selector(".ts-dropdown .option", count: 1000)
      end

      it "respects max_options value" do
        visit "/tom_select?data-tom-select-max-options-value=42"

        expect(page).to have_css("select[data-tom-select-max-options-value='42']", visible: false)

        find(".ts-control").click
        expect(page).to have_selector(".ts-dropdown .option", text: "Option 0")
        expect(page).to have_selector(".ts-dropdown .option", text: "Option 41")
        expect(page).to have_no_selector(".ts-dropdown .option", text: "Option 42")
        expect(page).to have_selector(".ts-dropdown .option", count: 42)
      end
    end
  end
end
