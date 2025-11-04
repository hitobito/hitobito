# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe "DisableToggle Stimulus Controller", js: true do
  before do
    stub_const("DisableToggleController", Class.new(ActionController::Base) { # rubocop:disable Rails/ApplicationController
      include Webpacker::Helper
      include ActionView::Helpers::AssetTagHelper

      helper_method :disable_toggle_tag

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
            <h1>DisableToggle Test</h1>
            #{disable_toggle_tag}
          </body>
        HTML
      end

      def disable_toggle_tag
        ctrl = "disable-toggle"
        <<~HTML
          <form data-controller="#{ctrl}">
            <label for="#{ctrl}-checkbox">Click me to enable button</label>
            <input type="checkbox" id="#{ctrl}-checkbox" name="#{ctrl}-checkbox" value="1" data-action="#{ctrl}#toggle"/>
            <br/>
            <input type="button" id="#{ctrl}-button" data-#{ctrl}-target="toggled"} disabled="disabled" value="Toggled"/>
          </form>
        HTML
      end
    })

    draw_test_routes do
      get "/disable_toggle", to: "disable_toggle#new"
    end
  end

  it "initializes disable_toggle" do
    visit "/disable_toggle"

    expect(page).to have_button "Toggled", disabled: true

    check "Click me to enable button"
    expect(page).to have_button "Toggled", disabled: false

    uncheck "Click me to enable button"
    expect(page).to have_button "Toggled", disabled: true

    check "Click me to enable button"
    expect(page).to have_button "Toggled", disabled: false
  end
end
