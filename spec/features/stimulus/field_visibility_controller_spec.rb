# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe "FieldVisibility Stimulus Controller", js: true do
  let(:ctrl) { "field-visibility" }

  def stub_form_with
    stub_const("FieldVisibilityController", Class.new(ActionController::Base) { # rubocop:disable Rails/ApplicationController
      include Webpacker::Helper
      include ActionView::Helpers::AssetTagHelper

      define_method :new do
        render inline: <<~HTML
          <head>
            #{stylesheet_pack_tag "application", media: "screen", "data-turbo-track": true}
            #{javascript_pack_tag "application", "data-turbo-track": true}
            <link rel="icon" href="data:image/x-icon;," type="image/x-icon">
          </head>
          <body>
            #{yield}
          </body>
        HTML
      end
    })

    draw_test_routes do
      get "/field_visibility", to: "field_visibility#new"
    end
    visit "/field_visibility"
  end

  it "shows container when checkbox value matches showWhen" do
    stub_form_with do
      <<~HTML
        <div data-controller="#{ctrl}"
             data-#{ctrl}-dependent-id-value="my-checkbox"
             data-#{ctrl}-show-when-value="1">
          <label for="my-checkbox">Toggle me</label>
          <input type="checkbox" id="my-checkbox" value="1">
          <h1 data-#{ctrl}-target="container" class="hidden">hi there</h1>
        </div>
      HTML
    end

    expect(page).not_to have_css "h1", text: "hi there"
    check "Toggle me"
    expect(page).to have_css "h1", text: "hi there"
    uncheck "Toggle me"
    expect(page).not_to have_css "h1", text: "hi there"
  end

  it "shows container when select value matches showWhen" do
    stub_form_with do
      <<~HTML
        <div data-controller="#{ctrl}"
             data-#{ctrl}-dependent-id-value="my-select"
             data-#{ctrl}-show-when-value="option2">
          <label for="my-select">Pick one</label>
          <select id="my-select">
            <option value="option1">Option 1</option>
            <option value="option2">Option 2</option>
            <option value="option3">Option 3</option>
          </select>
          <h1 data-#{ctrl}-target="container" class="hidden">hi there</h1>
        </div>
      HTML
    end

    expect(page).not_to have_css "h1", text: "hi there"
    select "Option 2", from: "Pick one"
    expect(page).to have_css "h1", text: "hi there"
    select "Option 3", from: "Pick one"
    expect(page).not_to have_css "h1", text: "hi there"
  end

  it "shows container when radio group value matches showWhen via event bubbling" do
    stub_form_with do
      <<~HTML
        <div data-controller="#{ctrl}"
             data-#{ctrl}-dependent-id-value="radio-group"
             data-#{ctrl}-show-when-value="2">
          <div id="radio-group">
            <label><input type="radio" name="choice" value="1"> Radio 1</label>
            <label><input type="radio" name="choice" value="2"> Radio 2</label>
            <label><input type="radio" name="choice" value="3"> Radio 3</label>
          </div>
          <h1 data-#{ctrl}-target="container" class="hidden">hi there</h1>
        </div>
      HTML
    end

    expect(page).not_to have_css "h1", text: "hi there"
    choose "Radio 1"
    expect(page).not_to have_css "h1", text: "hi there"
    choose "Radio 2"
    expect(page).to have_css "h1", text: "hi there"
    choose "Radio 3"
    expect(page).not_to have_css "h1", text: "hi there"
  end

  it "shows container based on data attribute of selected option with showWhenData" do
    stub_form_with do
      <<~HTML
        <div data-controller="#{ctrl}"
             data-#{ctrl}-dependent-id-value="my-select"
             data-#{ctrl}-show-when-data-value="highlight">
          <label for="my-select">Pick one</label>
          <select id="my-select">
            <option value="1">Option 1</option>
            <option value="2" data-highlight="true">Option 2</option>
            <option value="3">Option 3</option>
          </select>
          <h1 data-#{ctrl}-target="container" class="hidden">hi there</h1>
        </div>
      HTML
    end

    expect(page).not_to have_css "h1", text: "hi there"
    select "Option 2", from: "Pick one"
    expect(page).to have_css "h1", text: "hi there"
    select "Option 3", from: "Pick one"
    expect(page).not_to have_css "h1", text: "hi there"
  end

  it "shows container based on data attribute of radio element with showWhenData" do
    stub_form_with do
      <<~HTML
        <div data-controller="#{ctrl}"
             data-#{ctrl}-dependent-id-value="radio-group"
             data-#{ctrl}-show-when-data-value="highlight">
          <div id="radio-group">
            <label><input type="radio" name="choice" value="1"> Radio 1</label>
            <label><input type="radio" name="choice" value="2" data-highlight="true"> Radio 2</label>
            <label><input type="radio" name="choice" value="3"> Radio 3</label>
          </div>
          <h1 data-#{ctrl}-target="container" class="hidden">hi there</h1>
        </div>
      HTML
    end

    expect(page).not_to have_css "h1", text: "hi there"
    choose "Radio 2"
    expect(page).to have_css "h1", text: "hi there"
    choose "Radio 3"
    expect(page).not_to have_css "h1", text: "hi there"
  end

  it "clears input values when container is hidden with clearInputs" do
    stub_form_with do
      <<~HTML
        <div data-controller="#{ctrl}"
             data-#{ctrl}-dependent-id-value="my-checkbox"
             data-#{ctrl}-show-when-value="1"
             data-#{ctrl}-clear-inputs-value="true">
          <label for="my-checkbox">Toggle me</label>
          <input type="checkbox" id="my-checkbox" value="1">
          <div data-#{ctrl}-target="container" class="hidden">
            <label for="my-text">Text Field</label>
            <input type="text" id="my-text" value="">
          </div>
        </div>
      HTML
    end

    check "Toggle me"
    fill_in "Text Field", with: "hello"
    expect(page).to have_field("Text Field", with: "hello")

    uncheck "Toggle me"
    expect(page).to have_field("Text Field", with: "", visible: false)
  end
end
