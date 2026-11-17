# frozen_string_literal: true

#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

require "spec_helper"

describe "TransientModal Stimulus Controller", js: true do
  def stub_page(body = "")
    stub_const("TransientModalController", Class.new(ActionController::Base) { # rubocop:disable Rails/ApplicationController
      include ActionView::Helpers::AssetTagHelper
      include Propshaft::Helper

      define_method :show do
        render inline: <<~HTML
          <head>
            #{stylesheet_link_tag "application", media: "screen", "data-turbo-track": true}
            #{javascript_include_tag "core", "data-turbo-track": true}
            <link rel="icon" href="data:image/x-icon;," type="image/x-icon">
          </head>
          <body>
            #{body}
            <div id="modal-placeholder"></div>
          </body>
        HTML
      end
    })

    draw_test_routes do
      get "/transient_modal", to: "transient_modal#show"
    end
    visit "/transient_modal"
  end

  def modal_html(id, controller: true)
    <<~HTML
      <div id="#{id}" class="modal fade" tabindex="-1" #{'data-controller="transient-modal"' if controller}>
        <div class="modal-dialog">
          <div class="modal-content">
            <div class="modal-body">Body of #{id}</div>
            <a href="#" data-action="transient-modal#close">Close #{id}</a>
          </div>
        </div>
      </div>
    HTML
  end

  def insert_modal(id)
    page.execute_script(<<~JS)
      document.getElementById("modal-placeholder")
        .insertAdjacentHTML("beforeend", #{modal_html(id).to_json})
    JS
  end

  it "shows the modal when it is inserted" do
    stub_page

    insert_modal("confirmation")

    expect(page).to have_css("#confirmation.show", text: "Body of confirmation")
    expect(page).to have_css("body.modal-open")
  end

  it "removes the modal after closing it" do
    stub_page
    insert_modal("confirmation")
    expect(page).to have_css("#confirmation.show")

    click_link "Close confirmation"

    expect(page).to have_no_css("#confirmation", visible: :all)
    expect(page).to have_no_css(".modal-backdrop", visible: :all)
    expect(page).to have_no_css("body.modal-open")
  end

  it "closes a modal that is still open before showing" do
    stub_page(modal_html("selection", controller: false))
    page.execute_script('$("#selection").modal("show")')
    expect(page).to have_css("#selection.show", text: "Body of selection")

    insert_modal("confirmation")

    expect(page).to have_css("#confirmation.show", text: "Body of confirmation")
    expect(page).to have_no_css("#selection", visible: true)
    expect(page).to have_css(".modal-backdrop", count: 1, visible: :all)
  end

  it "closes the modal when closing it while it fades in" do
    stub_page

    page.execute_script(<<~JS)
      document.getElementById("modal-placeholder")
        .insertAdjacentHTML("beforeend", #{modal_html("confirmation").to_json})
      setTimeout(() => document.querySelector("#confirmation [data-action]").click())
    JS

    expect(page).to have_no_css("#confirmation", visible: :all)
    expect(page).to have_no_css("body.modal-open")
  end
end
