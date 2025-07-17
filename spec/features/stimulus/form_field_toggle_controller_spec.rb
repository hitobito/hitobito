# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe "FormFieldToggle Stimulus Controller", js: true do
  let(:ctrl) { "form-field-toggle" }

  def stub_form_with
    stub_const("FormFieldToggleController", Class.new(ActionController::Base) { # rubocop:disable Rails/ApplicationController
      include Webpacker::Helper
      include ActionView::Helpers::AssetTagHelper

      helper_method :form_field_toggle_tag

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
            <h1>FormFieldToggle Test</h1>
            #{yield}
          </body>
        HTML
      end
    })

    Rails.application.routes.send(:eval_block, lambda do
      get "/form_field_toggle", to: "form_field_toggle#new"
    end)
    visit "/form_field_toggle"
  end

  after do
    Rails.application.reload_routes!
  end

  it "does simple toggling of single element" do
    stub_form_with do
      <<~HTML
        <form data-controller="#{ctrl}">
        <label for="#{ctrl}-checkbox">toggle me</label>
        <input type="checkbox" id="#{ctrl}-checkbox" name="#{ctrl}-checkbox" value="1" data-action="#{ctrl}#toggle"/>
        <h1 data-#{ctrl}-target="toggle" class="hidden">hi there</div>
        </form>
      HTML
    end

    expect(page).not_to have_css "h1", text: "hi there"
    check "toggle me"
    expect(page).to have_css "h1", text: "hi there"
    uncheck "toggle me"
    expect(page).not_to have_css "h1", text: "hi there"
  end

  it "hides other values depending on value" do
    stub_form_with do
      <<~HTML
        <form data-controller="#{ctrl}" data-#{ctrl}-hide-on-value='["1", "2"]'>
          <div>
            <label for="#{ctrl}-radio-1">Radio 1</label>
            <input type="radio" id="#{ctrl}-radio-1" name="#{ctrl}-radio" value="1" data-action="#{ctrl}#toggle"/>
          </div>

          <div>
            <label for="#{ctrl}-radio-2">Radio 2</label>
            <input type="radio" id="#{ctrl}-radio-2" name="#{ctrl}-radio" value="2" data-action="#{ctrl}#toggle"/>
          </div>

          <div>
            <label for="#{ctrl}-radio-3">Radio 3</label>
            <input type="radio" id="#{ctrl}-radio-3" name="#{ctrl}-radio" value="3" data-action="#{ctrl}#toggle"/>
          </div>


          <h1 data-#{ctrl}-target="toggle" class="hidden">hi there</div>
        </form>
      HTML
    end

    expect(page).not_to have_css "h1", text: "hi there"
    choose "Radio 1"
    expect(page).not_to have_css "h1", text: "hi there"
    choose "Radio 2"
    expect(page).not_to have_css "h1", text: "hi there"
    choose "Radio 3"
    expect(page).to have_css "h1", text: "hi there"
    choose "Radio 2"
    expect(page).not_to have_css "h1", text: "hi there"
  end
end
