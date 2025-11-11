# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

require "rails_helper"

describe "self_registrations#create", type: :request do
  let(:group) { groups(:bottom_group_one_one) }
  let(:person) { people(:top_leader) }

  before do
    allow(FeatureGate).to receive(:enabled?).and_return(true)
    group.update!(self_registration_role_type: Group::BottomGroup::NoPermissions.name)
    group.update!(self_registration_require_adult_consent: true)

    file = Rails.root.join("spec", "fixtures", "files", "images", "logo.png")
    policy = ActiveStorage::Blob.create_and_upload!(io: File.open(file, "rb"),
      filename: "logo.png",
      content_type: "image/png").signed_id
    group.layer_group.update!(privacy_policy: policy)

    service_token.update!(register_people: true, permission: :layer_and_below_full,
      layer_group_id: group.layer_group_id)
  end

  it_behaves_like "jsonapi authorized requests", person: :skip do
    let(:payload) do
      {
        data: {
          type: "self_registrations",
          attributes: attributes
        }
      }
    end
    let(:attributes) {
      {
        first_name: "John",
        last_name: "Doe",
        nickname: "JD",
        company_name: nil,
        company: false,
        email: "test@puzzle.ch",
        adult_consent: true,
        privacy_policy_accepted: true
      }
    }

    subject(:make_request) do
      jsonapi_post "/api/groups/#{group.id}/self_registrations", payload
    end

    describe "basic create" do
      it "creates the resource" do
        expect {
          make_request
          expect(response.status).to eq(201), response.body
        }.to change { Role.count }.by(1).and change { Person.count }.by(1)
        expect(Person.last).to have_attributes(attributes.except(:adult_consent))
      end

      it "has side-effects that match the ones in the UI self registration" do
        group.update(self_registration_notification_email: "test@puzzle.ch")

        expect {
          make_request
          expect(response.status).to eq(201), response.body
        }.to change {
          Delayed::Job.where(Delayed::Job.arel_table[:handler]
            .matches("%DuplicateLocatorJob%")).count
        }.by(1)
          .and change { ActionMailer::Base.deliveries.count }.by(1)
          .and have_enqueued_mail(Groups::SelfRegistrationNotificationMailer,
            :self_registration_notification).exactly(:once)
      end
    end

    describe "with invalid email" do
      let(:attributes) {
        {
          first_name: "John",
          email: "hello world",
          adult_consent: true,
          privacy_policy_accepted: true
        }
      }

      it "raises validation error" do
        expect {
          make_request
          expect(response.status).to eq(422), response.body
          expect(errors.length).to eq(1)
          expect(errors[0].attribute).to eq("email")
          expect(errors[0].code).to eq("invalid")
          expect(errors[0].message).to eq("ist nicht gültig")
        }.not_to change { [Role.count, Person.count] }
      end
    end

    describe "with already used email" do
      let(:attributes) {
        {
          first_name: "John",
          email: people(:top_leader).email,
          adult_consent: true,
          privacy_policy_accepted: true
        }
      }

      it "raises validation error" do
        expect {
          make_request
          expect(response.status).to eq(422), response.body
          expect(errors.length).to eq(1)
          expect(errors[0].attribute).to eq("email")
          expect(errors[0].code).to eq("taken")
          expect(errors[0].message).to include("ist bereits vergeben. Diese Adresse muss für " \
            "alle Personen eindeutig sein,")
        }.not_to change { [Role.count, Person.count] }
      end
    end

    describe "with additional attribute" do
      let(:attributes) {
        {
          first_name: "John",
          address_care_of: "c/o Jane",
          adult_consent: true,
          privacy_policy_accepted: true
        }
      }

      it "raises invalid request" do
        expect {
          make_request
          expect(response.status).to eq(400), response.body
          expect(errors.length).to eq(1)
          expect(errors[0].attribute).to eq("data.attributes.address_care_of")
          expect(errors[0].code).to eq("unknown_attribute")
          expect(errors[0].message).to eq("is an unknown attribute")
        }.not_to change { [Role.count, Person.count] }
      end
    end

    describe "with existing id attribute" do
      let(:attributes) {
        {
          id: people(:top_leader).id,
          first_name: "John",
          email: "attacker@puzzle.ch",
          adult_consent: true,
          privacy_policy_accepted: true
        }
      }

      it "raises invalid request" do
        expect {
          make_request
          expect(response.status).to eq(400), response.body
          expect(errors.length).to eq(1)
          expect(errors[0].attribute).to eq("data.attributes.id")
          expect(errors[0].code).to eq("must_not_be_set")
          expect(errors[0].message).to eq("ID darf nicht gesetzt sein")
        }.not_to change { [Role.count, Person.count] }
      end
    end

    describe "with existing id in payload" do
      let(:payload) do
        {
          data: {
            id: people(:top_leader).id,
            type: "self_registrations",
            attributes: {
              first_name: "John",
              email: "attacker@puzzle.ch",
              adult_consent: true,
              privacy_policy_accepted: true
            }
          }
        }
      end

      it "raises invalid request" do
        expect {
          make_request
          expect(response.status).to eq(400), response.body
          expect(errors.length).to eq(1)
          expect(errors[0].attribute).to eq("data.id")
          expect(errors[0].code).to eq("must_not_be_set")
          expect(errors[0].message).to eq("ID darf nicht gesetzt sein")
        }.not_to change { [Role.count, Person.count] }
      end
    end

    describe "with role attribute" do
      let(:attributes) {
        {
          first_name: "John",
          roles: {
            type: Group::BottomGroup::Leader.name
          },
          adult_consent: true,
          privacy_policy_accepted: true
        }
      }

      it "raises invalid request" do
        expect {
          make_request
          expect(response.status).to eq(400), response.body
          expect(errors.length).to eq(1)
          expect(errors[0].attribute).to eq("data.attributes.roles")
          expect(errors[0].code).to eq("unknown_attribute")
          expect(errors[0].message).to eq("is an unknown attribute")
        }.not_to change { [Role.count, Person.count] }
      end
    end

    describe "with minimal attributes" do
      let(:attributes) {
        {
          first_name: "John",
          adult_consent: true,
          privacy_policy_accepted: true
        }
      }

      it "creates the resource" do
        expect {
          make_request
          expect(response.status).to eq(201), response.body
        }.to change { Role.count }.by(1).and change { Person.count }.by(1)
        expect(Person.last).to have_attributes(attributes.except(:adult_consent))
      end
    end

    describe "without name attribute" do
      let(:attributes) {
        {
          adult_consent: true,
          privacy_policy_accepted: true
        }
      }

      it "raises validation error" do
        expect {
          make_request
          expect(response.status).to eq(422), response.body
          expect(errors.length).to eq(1)
          expect(errors[0].attribute).to eq("base")
          expect(errors[0].code).to eq("name_missing")
          expect(errors[0].message).to eq("Bitte geben Sie einen Namen ein")
        }.not_to change { [Role.count, Person.count] }
      end
    end

    describe "in group with inactive self registration" do
      before { allow_any_instance_of(Group).to receive(:self_registration_active?).and_return(false) }

      it "raises 403 forbidden" do
        expect {
          make_request
          expect(response.status).to eq(403), response.body
        }.not_to change { [Role.count, Person.count] }
      end
    end

    describe "with missing register_people permission on service token" do
      before { service_token.update(register_people: false) }

      it "raises 403 forbidden" do
        expect {
          make_request
          expect(response.status).to eq(403), response.body
        }.not_to change { [Role.count, Person.count] }
      end
    end

    describe "with missing write permission on service token" do
      before { service_token.update(permission: :layer_and_below_read) }

      it "raises 403 forbidden" do
        expect {
          make_request
          expect(response.status).to eq(403), response.body
        }.not_to change { [Role.count, Person.count] }
      end
    end

    describe "without adult_consent" do
      let(:attributes) {
        {
          first_name: "John",
          privacy_policy_accepted: true
        }
      }

      it "raises invalid request" do
        expect {
          make_request
          expect(response.status).to eq(400), response.body
          expect(errors.length).to eq(1)
          expect(errors[0].attribute).to eq("adult_consent")
          expect(errors[0].code).to eq("must_be_accepted")
          expect(errors[0].message).to eq("muss akzeptiert werden")
        }.not_to change { [Role.count, Person.count] }
      end
    end

    describe "with adult_consent false" do
      let(:attributes) {
        {
          first_name: "John",
          adult_consent: false,
          privacy_policy_accepted: true
        }
      }

      it "raises invalid request" do
        expect {
          make_request
          expect(response.status).to eq(400), response.body
          expect(errors.length).to eq(1)
          expect(errors[0].attribute).to eq("adult_consent")
          expect(errors[0].code).to eq("must_be_accepted")
          expect(errors[0].message).to eq("muss akzeptiert werden")
        }.not_to change { [Role.count, Person.count] }
      end

      context "when no adult consent required" do
        before { group.update!(self_registration_require_adult_consent: false) }

        it "creates the resource" do
          expect {
            make_request
            expect(response.status).to eq(201), response.body
          }.to change { Role.count }.by(1).and change { Person.count }.by(1)
          expect(Person.last).to have_attributes(attributes.except(:adult_consent))
        end
      end
    end

    describe "without privacy_policy_accepted" do
      let(:attributes) {
        {
          first_name: "John",
          adult_consent: true
        }
      }

      it "raises validation error" do
        expect {
          make_request
          expect(response.status).to eq(422), response.body
          expect(errors.length).to eq(1)
          expect(errors[0].attribute).to eq("privacy_policy_accepted")
          expect(errors[0].code).to eq("must_be_accepted")
          expect(errors[0].message).to eq("muss akzeptiert werden")
        }.not_to change { [Role.count, Person.count] }
      end
    end

    describe "with privacy_policy_accepted false" do
      let(:attributes) {
        {
          first_name: "John",
          adult_consent: true,
          privacy_policy_accepted: false
        }
      }

      it "raises validation error" do
        expect {
          make_request
          expect(response.status).to eq(422), response.body
          expect(errors.length).to eq(1)
          expect(errors[0].attribute).to eq("privacy_policy_accepted")
          expect(errors[0].code).to eq("must_be_accepted")
          expect(errors[0].message).to eq("muss akzeptiert werden")
        }.not_to change { [Role.count, Person.count] }
      end

      context "when no privacy policy acceptance required" do
        before { group.layer_group.update!(privacy_policy: nil) }

        it "creates the resource" do
          expect {
            make_request
            expect(response.status).to eq(201), response.body
          }.to change { Role.count }.by(1).and change { Person.count }.by(1)
          expect(Person.last).to have_attributes(attributes.except(:adult_consent))
        end
      end

      context "when privacy policy acceptance for above layer required" do
        before do
          group.layer_group.update!(privacy_policy: nil)
          file = Rails.root.join("spec", "fixtures", "files", "images", "logo.png")
          policy = ActiveStorage::Blob.create_and_upload!(io: File.open(file, "rb"),
            filename: "logo.png",
            content_type: "image/png").signed_id
          group.layer_group.parent.update!(privacy_policy: policy)
        end

        it "raises validation error" do
          expect {
            make_request
            expect(response.status).to eq(422), response.body
            expect(errors.length).to eq(1)
            expect(errors[0].attribute).to eq("privacy_policy_accepted")
            expect(errors[0].code).to eq("must_be_accepted")
            expect(errors[0].message).to eq("muss akzeptiert werden")
          }.not_to change { [Role.count, Person.count] }
        end
      end
    end
  end
end
