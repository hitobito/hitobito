# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe People::Membership::VerifyController, type: :controller do
  render_views

  let(:person) { people(:bottom_member) }
  let(:verify_token) { person.membership_verify_token }
  let(:dom) { Capybara::Node::Simple.new(response.body) }

  before do
    top_layer = groups(:top_layer)
    top_layer.update!(street: "Muhrgasse", housenumber: "42a", zip_code: "4242", town: "Romyland")
  end

  describe "GET #show" do
    it "returns 404 if feature not enabled" do
      get :show, params: {verify_token: verify_token}

      expect(response.status).to eq 404
    end

    context "with feature enabled" do
      before { allow(People::Membership::Verifier).to receive(:enabled?).and_return(true) }

      it "confirms active membership" do
        allow_any_instance_of(People::Membership::Verifier).to receive(:member?).and_return(true)

        get :show, params: {verify_token: verify_token}

        expect(dom).to have_selector("#membership-verify header #root-address strong", text: "Top")
        expect(dom).to have_selector("#membership-verify header #root-address p", text: "Muhrgasse 42a4242 Romyland")

        expect(dom).to have_selector("#membership-verify #details #member-name", text: "Bottom Member")
        expect(dom).to have_selector("#membership-verify #details .alert-success", text: "Mitgliedschaft gültig")
        expect(dom).to have_selector("#membership-verify #details .alert-success span.fa-check")
      end

      it "confirms invalid membership" do
        allow_any_instance_of(People::Membership::Verifier).to receive(:member?).and_return(false)

        get :show, params: {verify_token: verify_token}

        expect(dom).to have_selector("#membership-verify #details #member-name", text: "Bottom Member")
        expect(dom).to have_selector("#membership-verify #details .alert-danger", text: "Keine gültige Mitgliedschaft")
        expect(dom).to have_selector("#membership-verify #details .alert-danger span.fa-times-circle")
      end

      it "returns invalid code message for non existent verify token" do
        get :show, params: {verify_token: "gits-nid"}

        expect(dom).to have_selector("#membership-verify header #root-address strong", text: "Top")
        expect(dom).to have_selector("#membership-verify header #root-address p", text: "Muhrgasse 42a4242 Romyland")

        expect(dom).to have_selector("#membership-verify #details .alert-danger", text: "Ungültiger Verifikationscode")
        expect(dom).to have_selector("#membership-verify #details .alert-danger span.fa-times-circle")
      end

      it "renders the website logo" do
        @initial_logo = Settings.application.logo.dup

        original_view_context = controller.view_context
        view_context = controller.view_context
        # In order to stub a method on the view_context we need to make sure our copy is used.
        allow(controller).to receive(:view_context).and_return(view_context)

        Settings.application.logo.image = "de_logo.png"
        logos = Settings.application.logo.multilanguage_image = {
          de: "de_logo.png",
          fr: "fr_logo.png",
          it: "it_logo.png"
        }
        logos[:default] = Settings.application.logo.image

        # Stub wagon_image_pack_tag to return logo or use original implementation for other images
        allow(view_context).to receive(:wagon_image_pack_tag) do |name, **options|
          if logos.value?(name)
            view_context.content_tag(:img, nil, src: name, **options)
          else
            original_view_context.wagon_image_pack_tag(name, **options)
          end
        end

        # Go through locales, render page and check dom for logo
        %i[de fr it en].each do |locale|
          I18n.with_locale(locale) do
            locale = :de if locale == :en
            get :show, params: {verify_token: "gits-nid"}
            dom = Capybara::Node::Simple.new(response.body)

            expect(dom).to have_selector("#logo")
            logo_img_src = dom.find("#logo img")[:src]
            expect(logo_img_src).to eq "#{locale}_logo.png"
            logo_img_alt = dom.find("#logo img")[:alt]
            expect(logo_img_alt).to eq "hitobito"
          end
        end

        Settings.application.logo = @initial_logo
      end
    end
  end
end
