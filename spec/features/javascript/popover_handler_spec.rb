# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

require "spec_helper"

describe "popover_handler.js", js: true do
  include ActionView::Helpers::UrlHelper
  include UtilityHelper
  include FormatHelper

  def render_page_with(&block) # rubocop:disable Metrics/MethodLength
    stub_const("PopoverTestController", Class.new(ActionController::Base) { # rubocop:disable Rails/ApplicationController
      include Webpacker::Helper
      include ActionView::Helpers::AssetTagHelper

      helper_method :popover_title, :popover_content

      define_method :new do
        # The HTML for your form element
        render inline: <<~HTML
          <head>
            #{stylesheet_pack_tag "application", media: "screen", "data-turbo-track": true}
            #{javascript_pack_tag "application", "data-turbo-track": true}
            <!-- add fake inline favicon to avoid 404 error -->
            <link rel="icon" href="data:image/x-icon;," type="image/x-icon">
          </head>
          <body>
            <h1>Popover Test</h1>
            #{yield}
          </body>
        HTML
      end
    })

    draw_test_routes do
      get "/popover_test", to: "popover_test#new"
    end
    visit "/popover_test"
  end

  def expect_popover_visible = expect(page).to have_css(".popover")

  def expect_popover_not_visible = expect(page).not_to have_css(".popover")

  def expect_popover_title = expect(page.find(".popover-header"))

  def render_link_with_popover(label, **opts)
    link_to(label, "#",
      "data-bs-toggle" => "popover",
      "data-bs-content" => popover_content,
      **opts)
  end

  let(:popover_title) { "Popover title" }
  let(:popover_content) { "This is the content of the popover." }

  describe "title" do
    %i[title data-bs-title].each do |title_attr|
      it "is rendered from #{title_attr} attribute" do
        render_page_with do
          render_link_with_popover("Click me for popover", title: popover_title)
        end

        expect_popover_not_visible
        click_link "Click me for popover"
        expect_popover_visible
        expect_popover_title.to have_text(popover_title)
      end

      it "is rendered from #{title_attr} attribute when data-anchor references a different element" do
        render_page_with do
          link_to("Some random element", "#", id: "some-element") +
            render_link_with_popover(
              "Click me for popover",
              "data-anchor" => "#some-element",
              title_attr => popover_title
            )
        end

        expect_popover_not_visible
        click_link "Click me for popover"
        expect_popover_visible
        expect_popover_title.to have_text(popover_title)
      end
    end
  end
end
