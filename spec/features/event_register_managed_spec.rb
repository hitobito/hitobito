# frozen_string_literal: true

#  Copyright (c) 2023-2024, CEVI Schweiz, Pfadibewegung Schweiz,
#  Jungwacht Blauring Schweiz, Pro Natura, Stiftung für junge Auslandschweizer.
#  This file is part of hitobito_youth and
#  licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_youth.

require "spec_helper"

describe "EventRegisterManaged", js: true do
  let(:bottom_member) { people(:bottom_member) }
  let(:top_leader) { people(:top_leader) }
  let(:group) { groups(:bottom_layer_one) }

  let(:user) { top_leader }

  before do
    sign_in(user)

    allow_any_instance_of(FeatureGate).to receive(:enabled?).and_call_original
  end

  [:event, :course].each do |event_type|
    context "for #{event_type}" do
      let(:event) { Fabricate(event_type, attrs_for_event_type(event_type)) }

      describe "registering existing managed" do
        let(:managed) { bottom_member }

        before do
          user.manageds = [managed]
          user.save!
        end

        context "with feature toggle disabled" do
          before do
            allow_any_instance_of(FeatureGate).to receive(:enabled?).with(:self_registration_reason).and_return(false)
            allow_any_instance_of(FeatureGate).to receive(:enabled?).with("people.people_managers").and_return(false)
            allow_any_instance_of(FeatureGate).to receive(:enabled?).with("email.bounces").and_return(true)
            allow_any_instance_of(FeatureGate).to receive(:enabled?).with("people.people_managers.self_service_managed_creation").and_return(false)
          end

          it "does not show dropdown option for existing managed" do
            visit group_event_path(group, event)

            expect(page).to_not have_css("a.dropdown-toggle", text: /Anmelden/i)
            expect(page).to_not have_css("dropdown-menu a", text: managed.full_name, exact_text: true)
            expect(page).to have_css("a.btn", text: /Anmelden/i)
          end
        end

        context "with people_managers feature toggle enabled" do
          before do
            allow_any_instance_of(FeatureGate).to receive(:enabled?).with(:self_registration_reason).and_return(false)
            allow_any_instance_of(FeatureGate).to receive(:enabled?).with("people.people_managers").and_return(true)
            allow_any_instance_of(FeatureGate).to receive(:enabled?).with("email.bounces").and_return(true)
            allow_any_instance_of(FeatureGate).to receive(:enabled?).with("people.people_managers.self_service_managed_creation").and_return(false)
          end

          it "shows dropdown option for existing managed" do
            visit group_event_path(group, event)

            expect(page).to have_css("a.dropdown-toggle", text: /Anmelden/i)
            find("a.dropdown-toggle", text: /Anmelden/i).click
            expect(page).to have_css("ul.dropdown-menu li a", text: managed.full_name, exact_text: true)
          end

          it "shows disabled dropdown option for existing managed since theyre already participating" do
            Event::Participation.create(event: event, person: managed)

            visit group_event_path(group, event)

            expect(page).to have_css("a.dropdown-toggle", text: /Anmelden/i)
            find("a.dropdown-toggle", text: /Anmelden/i).click
            expect(page).to have_css("ul.dropdown-menu li a.disabled", text: "#{managed.full_name} (ist bereits angemeldet)", exact_text: true)
          end

          it "allows you to create new participation for managed" do
            visit group_event_path(group, event)

            expect(page).to have_css("a.dropdown-toggle", text: /Anmelden/i)
            find("a.dropdown-toggle", text: /Anmelden/i).click
            expect(page).to have_css("ul.dropdown-menu li a", text: managed.full_name, exact_text: true)
            find("ul.dropdown-menu li a", text: managed.full_name, exact_text: true).click

            expect(page).to have_content "Kontaktangaben der teilnehmenden Person"
            contact_data_path = contact_data_group_event_participations_path(group, event)
            expect(current_path).to eq(contact_data_path)

            expect(page).to have_field("Vorname", with: managed.first_name)
            expect(page).to have_field("Nachname", with: managed.last_name)

            find_all('button.btn[type="submit"]').last.click
            expect(page).to have_content "Anmeldung als Teilnehmer/-in"
            expect(current_path).to eq(new_group_event_participation_path(group, event))

            expect do
              find_all('button.btn[type="submit"]').last.click
              expect(page).to have_content(participation_success_text_for_event(event, managed))
            end.to change { Event::Participation.count }.by(1)
          end

          it "allows you to create new participation for managed with privacy policy in hierarchy" do
            file = Rails.root.join("spec/fixtures/files/images/logo.png")
            image = ActiveStorage::Blob.create_and_upload!(io: File.open(file, "rb"),
              filename: "logo.png",
              content_type: "image/png").signed_id
            group.update(privacy_policy: image,
              privacy_policy_title: "Additional Policies Bottom Layer")

            visit group_event_path(group, event)

            expect(page).to have_css("a.dropdown-toggle", text: /Anmelden/i)
            find("a.dropdown-toggle", text: /Anmelden/i).click
            expect(page).to have_css("ul.dropdown-menu li a", text: managed.full_name, exact_text: true)
            find("ul.dropdown-menu li a", text: managed.full_name, exact_text: true).click

            expect(page).to have_content "Kontaktangaben der teilnehmenden Person"
            contact_data_path = contact_data_group_event_participations_path(group, event)
            expect(current_path).to eq(contact_data_path)

            expect(page).to have_field("Vorname", with: managed.first_name)
            expect(page).to have_field("Nachname", with: managed.last_name)

            find("input#event_participation_contact_datas_managed_privacy_policy_accepted").click
            find_all('button.btn[type="submit"]').last.click
            expect(page).to have_content "Anmeldung als Teilnehmer/-in"
            expect(current_path).to eq(new_group_event_participation_path(group, event))

            expect do
              find_all('button.btn[type="submit"]').last.click
              expect(page).to have_content(participation_success_text_for_event(event, managed))
            end.to change { Event::Participation.count }.by(1)
          end
        end

        context "via invitation" do
          before do
            Event::Invitation.create!(person: managed,
              event: event,
              participation_type: event.role_types.last)
          end

          context "with feature toggle disabled" do
            before do
              allow_any_instance_of(FeatureGate).to receive(:enabled?).with(:self_registration_reason).and_return(false)
              allow_any_instance_of(FeatureGate).to receive(:enabled?).with("email.bounces").and_return(true)
              allow_any_instance_of(FeatureGate).to receive(:enabled?).with("people.people_managers.self_service_managed_creation").and_return(false)
              allow_any_instance_of(FeatureGate).to receive(:enabled?).with("people.people_managers").and_return(false)
            end

            it "does not show invitation for existing managed" do
              visit group_event_path(group, event)

              expect(page).to_not have_css(".alert-warning", text: /#{managed.full_name} wurde zu diesem Anlass eingeladen/i)
            end
          end

          context "with feature toggle enabled" do
            before do
              allow_any_instance_of(FeatureGate).to receive(:enabled?).with(:self_registration_reason).and_return(false)
              allow_any_instance_of(FeatureGate).to receive(:enabled?).with("people.people_managers").and_return(true)
              allow_any_instance_of(FeatureGate).to receive(:enabled?).with("email.bounces").and_return(true)
              allow_any_instance_of(FeatureGate).to receive(:enabled?).with("people.people_managers.self_service_managed_creation").and_return(true)
            end

            it "shows invitation for existing managed" do
              visit group_event_path(group, event)

              expect(page).to have_css(".alert-warning", text: /#{managed.full_name} wurde zu diesem Anlass eingeladen/i)
            end

            it "allows you to create new participation for managed" do
              visit group_event_path(group, event)

              expect(page).to have_css(".alert-warning", text: /#{managed.full_name} wurde zu diesem Anlass eingeladen/i)
              find(".alert-warning a.btn", text: /Anmelden/i).click

              expect(page).to have_content "Kontaktangaben der teilnehmenden Person"
              contact_data_path = contact_data_group_event_participations_path(group, event)
              expect(current_path).to eq(contact_data_path)

              expect(page).to have_field("Vorname", with: managed.first_name)
              expect(page).to have_field("Nachname", with: managed.last_name)

              find_all('button.btn[type="submit"]').last.click
              expect(page).to have_content "Anmeldung als Teilnehmer/-in"
              expect(current_path).to eq(new_group_event_participation_path(group, event))

              expect do
                find_all('button.btn[type="submit"]').last.click
                expect(page).to have_content(participation_success_text_for_event(event, managed))
              end.to change { Event::Participation.count }.by(1)
            end
          end
        end
      end

      describe "registering new managed" do
        context "with people_managers feature toggle disabled" do
          before do
            allow_any_instance_of(FeatureGate).to receive(:enabled?).with(:self_registration_reason).and_return(false)
            allow_any_instance_of(FeatureGate).to receive(:enabled?).with("people.people_managers").and_return(false)
            allow_any_instance_of(FeatureGate).to receive(:enabled?).with("email.bounces").and_return(true)
          end

          context "with self_service_managed_creation feature toggle disabled" do
            before do
              allow_any_instance_of(FeatureGate).to receive(:enabled?).with("people.people_managers.self_service_managed_creation").and_return(false)
            end

            it "does not show dropdown option for new managed" do
              visit group_event_path(group, event)

              expect(page).to_not have_css("a.dropdown-toggle", text: /Anmelden/i)
              expect(page).to_not have_css("dropdown-menu a", text: /Neues Kind erfassen und anmelden/i)
              expect(page).to have_css("a.btn", text: /Anmelden/i)
            end
          end

          context "with self_service_managed_creation feature toggle enabled" do
            before do
              allow_any_instance_of(FeatureGate).to receive(:enabled?).with("people.people_managers.self_service_managed_creation").and_return(true)
            end

            it "does not show dropdown option for new managed" do
              visit group_event_path(group, event)

              expect(page).to_not have_css("a.dropdown-toggle", text: /Anmelden/i)
              expect(page).to_not have_css("dropdown-menu a", text: /Neues Kind erfassen und anmelden/i)
              expect(page).to have_css("a.btn", text: /Anmelden/i)
            end
          end
        end

        context "with people_managers feature toggle enabled" do
          before do
            allow_any_instance_of(FeatureGate).to receive(:enabled?).with(:self_registration_reason).and_return(false)
            allow_any_instance_of(FeatureGate).to receive(:enabled?).with("people.people_managers").and_return(true)
            allow_any_instance_of(FeatureGate).to receive(:enabled?).with("email.bounces").and_return(true)
          end

          context "with self_service_managed_creation feature toggle disabled" do
            before do
              allow_any_instance_of(FeatureGate).to receive(:enabled?).with("people.people_managers.self_service_managed_creation").and_return(false)
            end

            it "does not show dropdown option for new managed" do
              visit group_event_path(group, event)

              expect(page).to_not have_css("a.dropdown-toggle", text: /Anmelden/i)
              expect(page).to_not have_css("dropdown-menu a", text: /Neues Kind erfassen und anmelden/i)
              expect(page).to have_css("a.btn", text: /Anmelden/i)
            end
          end

          context "with self_service_managed_creation feature toggle enabled" do
            before do
              allow_any_instance_of(FeatureGate).to receive(:enabled?).with("people.people_managers.self_service_managed_creation").and_return(true)
            end

            it "shows dropdown option for new managed" do
              visit group_event_path(group, event)

              expect(page).to have_css("a.dropdown-toggle", text: /Anmelden/i)
              find("a.dropdown-toggle", text: /Anmelden/i).click
              expect(page).to have_css("ul.dropdown-menu li a", text: /Neues Kind erfassen und anmelden/i)
            end

            it "allows you to create new managed even if you cancel before creating participation" do
              visit group_event_path(group, event)

              expect(page).to have_css("a.dropdown-toggle", text: /Anmelden/i)
              find("a.dropdown-toggle", text: /Anmelden/i).click
              expect(page).to have_css("ul.dropdown-menu li a", text: /Neues Kind erfassen und anmelden/i)
              find("ul.dropdown-menu li a", text: /Neues Kind erfassen und anmelden/i).click

              expect(page).to have_content "Neues Kind registrieren und am Anlass anmelden"
              contact_data_path = contact_data_managed_group_event_participations_path(group, event)
              expect(current_path).to eq(contact_data_path)

              fill_in("Vorname", with: "Bob")
              fill_in("Nachname", with: "Miller")

              expect do
                find_all('button.btn[type="submit"]').last.click
                expect(page).to have_content "Anmeldung als Teilnehmer/-in"
              end.to change { Person.count }.by(1)

              new_managed = Person.last
              expect(new_managed.managers).to eq([user])

              expect(current_path).to eq(new_group_event_participation_path(group, event))

              expect do
                find("a.cancel").click
                # back on event#show
                expect(page).to have_content "Durchgeführt von"
              end.to_not change { Event::Participation.count }

              new_managed.reload
              expect(new_managed).to be_present
              expect(new_managed.managers).to eq([user])

              expect(current_path).to eq(group_event_path(group, event))
            end

            it "allows you to create new managed and participation for said person" do
              visit group_event_path(group, event)

              expect(page).to have_css("a.dropdown-toggle", text: /Anmelden/i)
              find("a.dropdown-toggle", text: /Anmelden/i).click
              expect(page).to have_css("ul.dropdown-menu li a", text: /Neues Kind erfassen und anmelden/i)
              find("ul.dropdown-menu li a", text: /Neues Kind erfassen und anmelden/i).click

              expect(page).to have_content "Neues Kind registrieren und am Anlass anmelden"
              contact_data_path = contact_data_managed_group_event_participations_path(group, event)
              expect(current_path).to eq(contact_data_path)

              fill_in("Vorname", with: "Bob")
              fill_in("Nachname", with: "Miller")

              expect do
                find_all('button.btn[type="submit"]').last.click
                expect(page).to have_content "Anmeldung als Teilnehmer/-in"
              end.to change { Person.count }.by(1)

              new_managed = Person.last
              expect(new_managed.managers).to eq([user])

              expect(current_path).to eq(new_group_event_participation_path(group, event))

              expect do
                find_all('button.btn[type="submit"]').last.click
                expect(page).to have_content(participation_success_text_for_event(event, new_managed))
              end.to change { Event::Participation.count }.by(1)
            end
          end
        end
      end
    end
  end

  def attrs_for_event_type(type)
    attrs = {application_opening_at: 5.days.ago, groups: [group], globally_visible: false, external_applications: true}
    case type
    when :course
      attrs.merge!(state: :application_open)
    end
    attrs
  end

  def participation_success_text_for_event(event, person)
    case event.class.sti_name
    when Event.sti_name
      "Teilnahme von #{person.full_name} in #{event.name} wurde erfolgreich erstellt."
    when Event::Course.sti_name
      "Es wurde eine Voranmeldung für Teilnahme von #{person.full_name} in #{event.name} erstellt"
    end
  end
end
