# frozen_string_literal: true

#  Copyright (c) 2021, Die Mitte. This file is part of
#  hitobito_die_mitte and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_die_mitte.

require "spec_helper"
describe "layouts/application.html.haml" do
  subject { Capybara::Node::Simple.new(rendered) }

  before do
    allow(controller).to receive(:current_person).and_return(person)
    allow(controller).to receive(:current_user).and_return(person)
    allow(controller).to receive(:origin_user).and_return(person)
    allow(view).to receive(:person_signed_in?).and_return(true)
    allow(view).to receive(:current_person).and_return(person)
    allow(view).to receive(:current_user).and_return(person)
    allow(view).to receive(:origin_user).and_return(person)
    allow(view).to receive(:person_home_path).and_return("")
  end

  context "nav-left" do
    let(:person) { people(:top_leader) }

    context "with roles" do
      it "shows nav-left" do
        render
        expect(subject).to have_css("nav.nav-left")
      end

      it "shows nav-left menu toggle button" do
        render
        expect(subject).to have_css("a.toggle-nav.visible-phone.d-md-none", text: "Menü")
      end

      it "shows logout button in nav menu" do
        render
        within("nav.nav-left") do
          expect(subject).to have_css("a.d-none.d-md-block", text: "Abmelden")
        end
      end

      # check for bootstrap md screensize class
      it "does not show general logout button on smaller screens" do
        render
        expect(subject).to have_css("a.d-md-block", text: "Abmelden")
      end
    end

    context "root user" do
      before do
        person.roles.destroy_all
        allow(person).to receive(:root?).and_return(true)
        render
      end

      it "shows nav-left" do
        expect(subject).to have_css("nav.nav-left")
      end

      it "shows nav-left menu toggle button" do
        expect(subject).to have_css("a.toggle-nav.visible-phone.d-md-none", text: "Menü")
      end

      it "shows logout button in nav menu" do
        within("nav.nav-left") do
          expect(subject).to have_css("a.d-none.d-md-block", text: "Abmelden")
        end
      end

      # check for bootstrap md screensize class
      it "does not show general logout button on smaller screens" do
        expect(subject).to have_css("a.d-md-block", text: "Abmelden")
      end
    end

    context "with basic_permission_only" do
      before do
        allow(person).to receive(:basic_permissions_only?).and_return(true)
        render
      end

      it "does not show nav-left" do
        expect(subject).not_to have_css("nav.nav-left")
      end

      it "does not show nav-left menu toggle button" do
        expect(subject).not_to have_css("a.toggle-nav.visible-phone.d-md-none", text: "Menü")
      end

      it "does not show logout button in nav menu" do
        within("nav.nav-left") do
          expect(subject).not_to have_css("a.d-none.d-md-block", text: "Abmelden")
        end
      end

      it "shows general logout button on smaller screens" do
        expect(subject).to have_css("a:not(.d-md-block)", text: "Abmelden")
      end
    end

    context "without roles" do
      before do
        person.roles.destroy_all
        render
      end

      it "does not show nav-left" do
        expect(subject).not_to have_css("nav.nav-left")
      end

      it "does not show nav-left menu toggle button" do
        expect(subject).not_to have_css("a.toggle-nav.visible-phone.d-md-none", text: "Menü")
      end

      it "does not show logout button in nav menu" do
        within("nav.nav-left") do
          expect(subject).not_to have_css("a.d-none.d-md-block", text: "Abmelden")
        end
      end

      it "shows general logout button on smaller screens" do
        expect(subject).to have_css("a:not(.d-md-block)", text: "Abmelden")
      end
    end
  end
end
