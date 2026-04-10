# frozen_string_literal: true

#  Copyright (c) 2026, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

require "spec_helper"

describe "Autosubmit Stimulus Controller", js: true do
  let(:ctrl) { "autosubmit" }

  def stub_page_with
    stub_const("AutosubmitTestController", Class.new(ActionController::Base) { # rubocop:disable Rails/ApplicationController
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
            <h1>Autosubmit Test</h1>
            #{yield}
          </body>
        HTML
      end

      define_method :create do
        render inline: <<~HTML
          <head>
            #{stylesheet_pack_tag "application", media: "screen", "data-turbo-track": true}
            #{javascript_pack_tag "application", "data-turbo-track": true}
            <link rel="icon" href="data:image/x-icon;," type="image/x-icon">
          </head>
          <body>
            <h1>Submitted</h1>
            <p id="autosubmit-value">#{params[:autosubmit]}</p>
            <p id="search-value">#{params[:search]}</p>
          </body>
        HTML
      end
    })

    draw_test_routes do
      get "/autosubmit_test", to: "autosubmit_test#new"
      post "/autosubmit_test", to: "autosubmit_test#create"
    end
  end

  it "submits the form when an input with autosubmit#submit action changes" do
    stub_page_with do
      <<~HTML
        <form action="/autosubmit_test" method="post" data-controller="#{ctrl}" data-#{ctrl}-delay-value="0">
          <input type="hidden" name="authenticity_token" value="test-token">
          <input type="hidden" name="autosubmit" value="">
          <label for="search">Search</label>
          <input type="text" id="search" name="search" data-action="input->#{ctrl}#submit">
        </form>
      HTML
    end

    visit "/autosubmit_test"
    fill_in "Search", with: "hello"

    expect(page).to have_content "Submitted"
    expect(find("#search-value")).to have_text "hello"
  end

  it "sets autosubmit hidden field to the triggering input name" do
    stub_page_with do
      <<~HTML
        <form action="/autosubmit_test" method="post" data-controller="#{ctrl}" data-#{ctrl}-delay-value="0">
          <input type="hidden" name="authenticity_token" value="test-token">
          <input type="hidden" name="autosubmit" value="">
          <label for="search">Search</label>
          <input type="text" id="search" name="search" data-action="input->#{ctrl}#submit">
        </form>
      HTML
    end

    visit "/autosubmit_test"
    fill_in "Search", with: "test"

    expect(page).to have_content "Submitted"
    expect(find("#autosubmit-value")).to have_text "search"
  end

  it "clears the input and submits the form" do
    stub_page_with do
      <<~HTML
        <form action="/autosubmit_test" method="post" data-controller="#{ctrl}" data-#{ctrl}-delay-value="0">
          <input type="hidden" name="authenticity_token" value="test-token">
          <input type="hidden" name="autosubmit" value="">
          <label for="search">Search</label>
          <input type="text" id="search" name="search" value="prefilled" data-action="autosubmit#submit">
          <button type="button" data-action="#{ctrl}#clear">Clear</button>
        </form>
      HTML
    end

    visit "/autosubmit_test"
    expect(page).to have_field "Search", with: "prefilled"

    click_button "Clear"

    expect(page).to have_content "Submitted"
    expect(find("#search-value", visible: :all).text).to be_empty
  end

  it "disables frontend form validation during autosubmit" do
    stub_page_with do
      <<~HTML
        <form action="/autosubmit_test" method="post" data-controller="#{ctrl}" data-#{ctrl}-delay-value="0">
          <input type="hidden" name="authenticity_token" value="test-token">
          <input type="hidden" name="autosubmit" value="">
          <label for="search">Search</label>
          <input type="text" id="search" name="search" data-action="input->#{ctrl}#submit">
          <input type="text" name="required_field" required>
        </form>
      HTML
    end

    visit "/autosubmit_test"

    # Even though required_field is empty, autosubmit should bypass frontend validation
    fill_in "Search", with: "test"

    expect(page).to have_content "Submitted"
  end

  it "submits with a select change event" do
    stub_page_with do
      <<~HTML
        <form action="/autosubmit_test" method="post" data-controller="#{ctrl}" data-#{ctrl}-delay-value="0">
          <input type="hidden" name="authenticity_token" value="test-token">
          <input type="hidden" name="autosubmit" value="">
          <label for="search">Category</label>
          <select id="search" name="search" data-action="change->#{ctrl}#submit">
            <option value="">Select</option>
            <option value="alpha">Alpha</option>
            <option value="beta">Beta</option>
          </select>
        </form>
      HTML
    end

    visit "/autosubmit_test"
    select "Beta", from: "Category"

    expect(page).to have_content "Submitted"
    expect(find("#search-value")).to have_text "beta"
  end
end
