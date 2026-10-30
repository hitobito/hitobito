# frozen_string_literal: true

#  Copyright (c) 2025-2026, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

require "spec_helper"

describe "DisableToggle Stimulus Controller", js: true do
  let(:ctrl) { "disable-toggle" }

  def stub_form_with
    stub_const("DisableToggleController", Class.new(ActionController::Base) { # rubocop:disable Rails/ApplicationController
      include ActionView::Helpers::AssetTagHelper
      include Propshaft::Helper

      helper_method :disable_toggle_tag

      define_method :new do
        # The HTML for your form element
        render inline: <<~HTML
          <head>
            #{stylesheet_link_tag "application", media: "screen", "data-turbo-track": true}
            #{javascript_include_tag "core", "data-turbo-track": true}
            <!-- add fake inline favicon to avoid 404 error -->
            <link rel="icon" href="data:image/x-icon;," type="image/x-icon">
          </head>
          <body>
            <h1>DisableToggle Test</h1>
            #{yield}
          </body>
        HTML
      end
    })

    draw_test_routes do
      get "/disable_toggle", to: "disable_toggle#new"
    end

    visit "/disable_toggle"
  end

  it "initializes disable_toggle" do
    stub_form_with do
      <<~HTML
        <form data-controller="#{ctrl}">
          <label for="#{ctrl}-checkbox">Click me to enable button</label>
          <input type="checkbox" id="#{ctrl}-checkbox" name="#{ctrl}-checkbox" value="1" data-action="#{ctrl}#toggle"/>
          <br/>
          <input type="button" id="#{ctrl}-button" data-#{ctrl}-target="toggled"} disabled="disabled" value="Toggled"/>
        </form>
      HTML
    end

    expect(page).to have_button "Toggled", disabled: true

    check "Click me to enable button"
    expect(page).to have_button "Toggled", disabled: false

    uncheck "Click me to enable button"
    expect(page).to have_button "Toggled", disabled: true

    check "Click me to enable button"
    expect(page).to have_button "Toggled", disabled: false
  end

  it "initializes disable_toggle" do
    stub_form_with do
      <<~HTML
        <form data-controller="#{ctrl}">
          <label for="#{ctrl}-checkbox-1">Click 1 to enable button</label>
          <input type="checkbox" id="#{ctrl}-checkbox-1" name="#{ctrl}-checkbox" value="1" data-action="#{ctrl}#toggle"/>
          <label for="#{ctrl}-checkbox-2">Click 2 to enable button</label>
          <input type="checkbox" id="#{ctrl}-checkbox-2" name="#{ctrl}-checkbox" value="1" data-action="#{ctrl}#toggle"/>
          <br/>
          <input type="button" id="#{ctrl}-button" data-#{ctrl}-target="toggled"} disabled="disabled" value="Toggled"/>
        </form>
      HTML
    end

    expect(page).to have_button "Toggled", disabled: true

    check "Click 1 to enable button"
    expect(page).to have_button "Toggled", disabled: true
    check "Click 2 to enable button"
    expect(page).to have_button "Toggled", disabled: false

    uncheck "Click 1 to enable button"
    expect(page).to have_button "Toggled", disabled: true

    check "Click 1 to enable button"
    expect(page).to have_button "Toggled", disabled: false
  end

  it "toggles multiple toggled and inverted targets" do
    stub_form_with do
      <<~HTML
        <form data-controller="#{ctrl}">
          <label for="#{ctrl}-checkbox">Click me to toggle</label>
          <input type="checkbox" id="#{ctrl}-checkbox" name="#{ctrl}-checkbox" value="1" data-action="#{ctrl}#toggle"/>
          <br/>
          <input type="button" data-#{ctrl}-target="toggled" disabled="disabled" value="Toggled 1"/>
          <input type="button" data-#{ctrl}-target="toggled" disabled="disabled" value="Toggled 2"/>
          <input type="button" data-#{ctrl}-target="inverted" value="Inverted 1"/>
          <input type="button" data-#{ctrl}-target="inverted" value="Inverted 2"/>
        </form>
      HTML
    end

    check "Click me to toggle"
    expect(page).to have_button "Toggled 1", disabled: false
    expect(page).to have_button "Toggled 2", disabled: false
    expect(page).to have_button "Inverted 1", disabled: true
    expect(page).to have_button "Inverted 2", disabled: true

    uncheck "Click me to toggle"
    expect(page).to have_button "Toggled 1", disabled: true
    expect(page).to have_button "Toggled 2", disabled: true
    expect(page).to have_button "Inverted 1", disabled: false
    expect(page).to have_button "Inverted 2", disabled: false
  end
end
