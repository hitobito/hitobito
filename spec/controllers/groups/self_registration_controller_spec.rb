# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of hitobito and licensed under the
#  Affero General Public License version 3 or later. See the COPYING file at the top-level directory
#  or at https://github.com/hitobito/hitobito.

require "spec_helper"

describe Groups::SelfRegistrationController do
  let(:role_type) { Group::TopGroup::Member }
  let(:group) { groups(:top_group) }
  let(:person) { people(:top_leader) }

  context "with feature disabled" do
    before do
      group.update!(self_registration_role_type: Group::TopGroup::Member.sti_name)
      allow(Settings.groups.self_registration).to receive(:enabled).and_return(false)
    end

    describe "GET#show" do
      it "redirects to group if signed in" do
        sign_in(person)

        get :show, params: {group_id: group.id}

        expect(response).to redirect_to(group_path(group.id))
      end
    end

    it "redirects to group if group has registration disabled" do
      group.update!(self_registration_role_type: "")

      get :show, params: {group_id: group.id}
      expect(response).to redirect_to(group_path(group.id))
    end

    it "redirects to group if group has registration enabled" do
      get :show, params: {group_id: group.id}

      expect(response).to redirect_to(group_path(group.id))
    end

    describe "POST create" do
      it "redirects to group" do
        sign_in(person)

        post :create, params: {
          group_id: group.id,
          new_user_form: {email: "foo@example.com"}
        }

        expect(response).to redirect_to(group_path(group.id))
      end
    end
  end

  context "with feature enabled" do
    before do
      allow(Settings.groups.self_registration).to receive(:enabled).and_return(true)
    end

    context "GET#show" do
      context "when registration active" do
        before do
          group.update(self_registration_role_type: Group::TopGroup::Member.sti_name)
        end

        context "when unautorized" do
          it "renders page" do
            get :show, params: {group_id: group.id}

            expect(response).to render_template("groups/self_registration/show")
          end

          it "redirects to group if group has registration disabled" do
            group.update!(self_registration_role_type: "")

            get :show, params: {group_id: group.id}

            expect(response).to redirect_to(group_path(group.id))
          end
        end

        context "when authorized" do
          it "redirects to self_inscription_path" do
            sign_in(person)

            get :show, params: {group_id: group.id}

            expect(response).to redirect_to(group_self_inscription_path(group.id))
          end
        end
      end

      context "when registration is inactive" do
        it "redirects to group" do
          sign_in(person)

          get :show, params: {group_id: group.id}

          expect(response).to redirect_to(group_path(group.id))
        end
      end
    end

    context "POST#create" do
      context "when registration active" do
        before do
          group.update!(self_registration_role_type: Group::TopGroup::Member.sti_name)
        end

        context "with privacy policies in hierarchy" do
          before do
            file = Rails.root.join("spec", "fixtures", "files", "images", "logo.png")
            image = ActiveStorage::Blob.create_and_upload!(io: File.open(file, "rb"),
              filename: "logo.png",
              content_type: "image/png").signed_id
            group.layer_group.update(privacy_policy: image)
          end

          it "creates person and role if privacy policy is accepted, schedules duplicate locator job" do
            expect do
              post :create, params: {
                group_id: group.id,
                wizards_register_new_user_wizard: {
                  new_user_form: {first_name: "Bob", last_name: "Miller", privacy_policy_accepted: "1"}
                }
              }
            end.to change { Person.count }.by(1)
              .and change { Role.count }.by(1)
              .and change { ActionMailer::Base.deliveries.count }.by(0)

            person = Person.find_by(first_name: "Bob", last_name: "Miller")
            role = person.roles.first

            expect(person.primary_group).to eq(group)
            expect(person.privacy_policy_accepted).to be_present
            expect(person.full_name).to eq("Bob Miller")
            expect(role.type).to eq(Group::TopGroup::Member.sti_name)
            expect(role.group).to eq(group)

            expect(response).to redirect_to(new_person_session_path)
          end

          it "creates person and schedules duplicate location job" do
            expect do
              post :create, params: {
                group_id: group.id,
                wizards_register_new_user_wizard: {
                  new_user_form: {first_name: "Alfred", last_name: "Burn", privacy_policy_accepted: "1"}
                }
              }
            end.to change { Person.count }.by(1)
              .and change {
                Delayed::Job
                  .where(Delayed::Job
                  .arel_table[:handler]
                  .matches("%DuplicateLocatorJob%"))
                  .count
              }.by(1)

            person = Person.find_by(first_name: "Alfred", last_name: "Burn")
            expect(person.primary_group).to eq(group)

            expect(response).to redirect_to(new_person_session_path)
          end

          it "does not create a person if privacy policy is not accepted" do
            expect do
              post :create, params: {
                group_id: group.id,
                wizards_register_new_user_wizard: {
                  new_user_form: {first_name: "Bob", last_name: "Miller", privacy_policy_accepted: "0"}
                }
              }
            end.to change { Person.count }.by(0)
              .and change { Role.count }.by(0)
              .and change { ActionMailer::Base.deliveries.count }.by(0)
          end
        end

        it "redirects to login if honeypot filled" do
          post :create, params: {
            group_id: group.id,
            verification: "foo",
            new_user_form: {email: "foo@example.com"}
          }

          expect(response).to redirect_to(new_person_session_path)
        end

        it "creates person and role" do
          expect do
            post :create, params: {
              group_id: group.id,
              wizards_register_new_user_wizard: {
                new_user_form: {first_name: "Bob", last_name: "Miller"}
              }
            }
          end.to change { Person.count }.by(1)
            .and change { Role.count }.by(1)
            .and change { ActionMailer::Base.deliveries.count }.by(0)

          person = Person.find_by(first_name: "Bob", last_name: "Miller")
          role = person.roles.first

          expect(person.primary_group).to eq(group)
          expect(person.full_name).to eq("Bob Miller")
          expect(role.type).to eq(Group::TopGroup::Member.sti_name)
          expect(role.group).to eq(group)

          expect(response).to redirect_to(new_person_session_path)
        end

        it "raises when person save! fails" do
          allow_any_instance_of(Person).to receive(:save!).and_raise
          expect do
            post :create, params: {
              group_id: group.id,
              wizards_register_new_user_wizard: {
                new_user_form: {first_name: "Bob", last_name: "Miller"}
              }
            }
          end.to raise_error(RuntimeError)
        end

        it "does not send any emails when no email provided" do
          expect_no_enqueued_mail_jobs do
            post :create, params: {
              group_id: group.id,
              wizards_register_new_user_wizard: {
                new_user_form: {first_name: "Bob", last_name: "Miller"}
              }
            }
          end
        end

        it "sends password reset instructions" do
          expect do
            post :create, params: {
              group_id: group.id,
              wizards_register_new_user_wizard: {
                new_user_form: {first_name: "Bob", last_name: "Miller", email: "foo@example.com"}
              }
            }
          end.to change { ActionMailer::Base.deliveries.count }.by(1)
        end

        it "sends notification mail" do
          group.update(self_registration_notification_email: "notification@example.com")

          expect_enqueued_mail_jobs(count: 1) do
            post :create, params: {
              group_id: group.id,
              wizards_register_new_user_wizard: {
                new_user_form: {first_name: "Bob", last_name: "Miller"}
              }
            }
          end
        end
      end
    end
  end
end
