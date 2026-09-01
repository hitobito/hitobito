# frozen_string_literal: true

#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

require "spec_helper"
require "timeout"

describe "Spinner Stimulus Controller", js: true do
  let(:ctrl) { "spinner" }

  # Queue to control AJAX request completion timing in tests.
  # This allows us to observe the spinner in its active state (while AJAX is in-flight)
  # and precisely control when the AJAX completes (by calling complete_ajax)
  # without waiting for a hardcoded time (tests would run longer and are potentially flaky)
  let(:ajax_queue) { Queue.new }

  # Call with block to define page content
  def stub_page_with(&block) # rubocop:disable Metrics/AbcSize
    define_test_controller(&block)
    define_test_routes
    visit "/spinner_test"
  end

  def define_test_controller
    stub_const("SpinnerController", Class.new(ActionController::Base) { # rubocop:disable Rails/ApplicationController
      include Webpacker::Helper
      include ActionView::Helpers::AssetTagHelper

      define_method :new do
        render inline: <<~HTML
          <head>
            #{stylesheet_pack_tag "application", media: "screen", "data-turbo-track": true}
            #{javascript_pack_tag "application", "data-turbo-track": true}
          </head>
          <body>
            <h1>Spinner Test</h1>
            #{yield}
          </body>
        HTML
      end
    })
  end

  def define_test_routes
    queue = ajax_queue

    draw_test_routes do
      get "/spinner_test", to: "spinner#new"
      # Add routes to prevent routing errors for assets
      get "/favicon.ico", to: proc { [204, {}, []] }
      get "/spinner.gif", to: proc { [204, {}, []] }
      # AJAX endpoint that blocks until test releases it
      post "/test_submit", to: proc { |env|
        # Wait for test to release, with timeout matching Capybara's wait time.
        # The timeout prevents tests from hanging forever if the controller is broken
        # and AJAX events never fire (e.g., if Stimulus actions aren't registered correctly).
        Timeout.timeout(Capybara.default_max_wait_time) do
          queue.pop  # Block until test pushes to queue
        end
        [200, {"Content-Type" => "application/json"}, ['{"status":"ok"}']]
      }
    end
  end

  def complete_ajax
    ajax_queue.push(true)
  end

  context "with icon replacement" do
    it "replaces icon with spinner on form submit and restores it" do
      stub_page_with do
        <<~HTML
          <form id="test-form" action="/test_submit" method="post">
            <button type="submit" id="submit-btn" data-controller="#{ctrl}" data-remote="true">
              <i class="fas fa-add"></i> Submit
            </button>
          </form>
        HTML
      end

      # Initial state - icon should be fa-add
      expect(page).to have_css("#submit-btn i.fa-add")
      expect(page).not_to have_css("#submit-btn i.fa-spinner")

      # Submit form triggers AJAX request (Turbo intercepts automatically)
      find("#submit-btn").click

      # Icon should be replaced with spinner while AJAX is in progress
      expect(page).to have_css("#submit-btn i.fa-spinner.fa-spin")
      expect(page).not_to have_css("#submit-btn i.fa-add")
      expect(page).to have_css("#submit-btn.disabled")

      # Release AJAX request to complete
      complete_ajax

      # Icon should be restored after AJAX completes
      expect(page).to have_css("#submit-btn i.fa-add")
      expect(page).not_to have_css("#submit-btn i.fa-spinner")
      expect(page).not_to have_css("#submit-btn.disabled")
    end
  end

  context "with spinner element target" do
    it "shows spinner element on form submit" do
      stub_page_with do
        <<~HTML
          <form id="test-form" action="/test_submit" method="post">
            <button type="submit" id="submit-btn" data-controller="#{ctrl}" data-remote="true">
              <span data-#{ctrl}-target="spinnerElement" style="display: none;">Loading...</span>
              Submit
            </button>
          </form>
        HTML
      end

      # Initial state - spinner should be hidden
      expect(page).to have_css("span[data-#{ctrl}-target='spinnerElement']", visible: :hidden)

      # Submit form - Turbo will trigger AJAX request
      find("#submit-btn").click

      # Spinner should be visible while AJAX is in progress
      expect(page).to have_css("span[data-#{ctrl}-target='spinnerElement']", visible: :visible)
      expect(page).to have_css("#submit-btn.disabled")

      # Release AJAX request to complete
      complete_ajax

      # Spinner should be hidden again after AJAX completes
      expect(page).to have_css("span[data-#{ctrl}-target='spinnerElement']", visible: :hidden)
      expect(page).not_to have_css("#submit-btn.disabled")
    end
  end

  context "with external spinner selector" do
    it "shows external spinner on form submit" do
      stub_page_with do
        <<~HTML
          <form id="test-form" action="/test_submit" method="post">
            <button type="submit" id="submit-btn" data-controller="#{ctrl}" data-remote="true" data-#{ctrl}-selector-value="#external-spinner">Submit</button>
          </form>
          <span id="external-spinner" style="display: none;">Loading...</span>
        HTML
      end

      # Initial state: external spinner should be hidden
      expect(page).to have_css("#external-spinner", visible: :hidden)

      # Submit form triggers AJAX request (Turbo intercepts automatically)
      find("#submit-btn").click

      # External spinner should be visible while AJAX is in progress
      expect(page).to have_css("#external-spinner", visible: :visible)
      expect(page).to have_css("#submit-btn.disabled")

      # Release AJAX request to complete
      complete_ajax

      # External spinner should be hidden again after AJAX completes
      expect(page).to have_css("#external-spinner", visible: :hidden)
      expect(page).not_to have_css("#submit-btn.disabled")
    end
  end

  context "with AJAX form" do
    it "shows spinner on turbo:submit-start and hides on turbo:submit-end" do
      stub_page_with do
        <<~HTML
          <form id="test-form" action="/test_submit" method="post">
            <button type="submit" id="submit-btn" data-controller="#{ctrl}" data-remote="true">
              <i class="fas fa-save"></i> Submit
            </button>
          </form>
        HTML
      end

      # Initial state: icon should be visible
      expect(page).to have_css("#submit-btn i.fa-save")
      expect(page).not_to have_css("#submit-btn i.fa-spinner")

      # Submit form triggers AJAX request (Turbo intercepts automatically)
      find("#submit-btn").click

      # Icon should be replaced with spinner while AJAX is in progress
      expect(page).to have_css("#submit-btn i.fa-spinner.fa-spin")
      expect(page).to have_css("#submit-btn.disabled")

      # Release AJAX request to complete
      complete_ajax

      # Icon should be restored after AJAX completes
      expect(page).to have_css("#submit-btn i.fa-save")
      expect(page).not_to have_css("#submit-btn i.fa-spinner")
      expect(page).not_to have_css("#submit-btn.disabled")
    end
  end

  context "with sibling spinner" do
    it "shows sibling spinner element on form submit" do
      stub_page_with do
        <<~HTML
          <form id="test-form" action="/test_submit" method="post">
            <button type="submit" id="submit-btn" data-controller="#{ctrl}" data-remote="true">Submit</button>
            <img src="/spinner.gif" class="spinner" style="display: none;" />
          </form>
        HTML
      end

      # Initial state: spinner should be hidden
      expect(page).to have_css("img.spinner", visible: :hidden)

      # Submit form triggers AJAX request (Turbo intercepts automatically)
      find("#submit-btn").click

      # Sibling spinner should be visible while AJAX is in progress
      expect(page).to have_css("img.spinner", visible: :visible)
      expect(page).to have_css("#submit-btn.disabled")

      # Release AJAX request to complete
      complete_ajax

      # Sibling spinner should be hidden again after AJAX completes
      expect(page).to have_css("img.spinner", visible: :hidden)
      expect(page).not_to have_css("#submit-btn.disabled")
    end
  end

  context "with normal link" do
    it "shows spinner when clicking a non-AJAX link" do
      stub_page_with do
        <<~HTML
          <a href="javascript:void(0)" id="test-link" data-controller="#{ctrl}">
            <i class="fas fa-external-link"></i> Go to page
          </a>
        HTML
      end

      # Initial state
      expect(page).to have_css("#test-link i.fa-external-link")
      expect(page).not_to have_css("#test-link i.fa-spinner")

      find("#test-link").click

      # Spinner should appear (handleClick calls show())
      expect(page).to have_css("#test-link i.fa-spinner.fa-spin")
      expect(page).to have_css("#test-link.disabled")
    end
  end

  context "with timeout value" do
    it "auto-hides spinner after specified timeout for download links" do
      stub_page_with do
        <<~HTML
          <a href="javascript:void(0)" id="download-link" data-controller="#{ctrl}" data-#{ctrl}-timeout-value="500">
            <i class="fas fa-download"></i> Download
          </a>
        HTML
      end

      # Initial state
      expect(page).to have_css("#download-link i.fa-download")
      expect(page).not_to have_css("#download-link i.fa-spinner")

      find("#download-link").click

      # Spinner should appear immediately
      expect(page).to have_css("#download-link i.fa-spinner.fa-spin")
      expect(page).to have_css("#download-link.disabled")

      # After timeout (500ms), spinner should auto-hide
      # Set Capybara wait time slightly longer than timeout to observe the change
      using_wait_time([Capybara.default_max_wait_time, 0.7].max) do
        expect(page).to have_css("#download-link i.fa-download")
        expect(page).not_to have_css("#download-link i.fa-spinner")
        expect(page).not_to have_css("#download-link.disabled")
      end
    end
  end
end
