#  frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Wanderwege. This file is part of
#  hitobito_sww and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sww.

require 'spec_helper'

describe PersonResource, type: :resource do
  let(:user) { user_role.person }

  around do |example|
    RSpec::Mocks.with_temporary_scope do
      Graphiti.with_context(double({
        current_ability: Ability.new(user),
        entry: try(:person),
      })) { example.run }
    end
  end

  describe 'creating' do
    let!(:user_role) { Fabricate(Group::BottomLayer::Leader.name, person: Fabricate(:person), group: groups(:bottom_layer_one)) }

    let(:payload) do
      {
        data: {
          type: 'people',
          attributes: Fabricate.attributes_for(:person).except(*Person::INTERNAL_ATTRS.map(&:to_s))
        }
      }
    end

    let(:instance) do
      PersonResource.build(payload)
    end

    it 'works' do
      expect {
        expect(instance.save).to eq(true), instance.errors.full_messages.to_sentence
      }.to change { Person.count }.by(1)
    end
  end

  describe 'updating' do
    let!(:user_role) { Fabricate(Group::BottomLayer::Leader.name, person: Fabricate(:person), group: groups(:bottom_layer_one)) }
    let!(:person) { Fabricate(:person, first_name: 'Franz', updated_at: 1.second.ago, gender: 'm') }
    let!(:role) { Fabricate(Group::BottomLayer::Member.name, person: person, group: groups(:bottom_layer_one)) }

    let(:payload) do
      {
        id: person.id.to_s,
        data: {
          id: person.id.to_s,
          type: 'people',
          attributes: {
            first_name: 'Joseph'
          }
        }
      }
    end

    let(:instance) do
      PersonResource.find(payload)
    end

    it 'works' do
      expect {
        expect(instance.update_attributes).to eq(true)
      }.to change { person.reload.updated_at }
       .and change { person.first_name }.to('Joseph')
    end


    context 'for person language' do
      let(:payload) do
        {
          id: person.id.to_s,
          data: {
            id: person.id.to_s,
            type: 'people',
            attributes: {
              language: target_value
            }
          }
        }
      end

      context 'with valid value' do
        let(:target_value) { 'fr' }

        it 'works' do
          expect {
            expect(instance.update_attributes).to eq(true)
          }.to change { person.reload.updated_at }
            .and change { person.language }.to('fr')
        end
      end

      context 'with invalid value' do
        let(:target_value) { 'elvish' }

        it 'works' do
          expect {
            expect(instance.update_attributes).to eq(false)
          }.to_not change { [person.reload.updated_at, person.language] }
        end

      end

    end

    context 'with show_details permission, it' do
      it 'updates restricted attrs' do
        new_birthday = Date.today
        payload[:data][:attributes][:gender] = 'w'
        payload[:data][:attributes][:birthday] = new_birthday.to_json

        expect {
          expect(instance.update_attributes).to eq(true)
        }.to change { person.reload.updated_at }
         .and change { person.gender }.to('w')
         .and change { person.birthday }.to(new_birthday)
      end
    end

    context 'without show_details permission, it' do
      before do
        skip 'We currently have no roles (and indeed no permissions which we could give to roles), which grant update ability without also granting show_details ability.'
      end

      it  'does not update restricted attrs' do
        new_birthday = Date.today
        payload[:data][:attributes][:gender] = 'w'
        payload[:data][:attributes][:birthday] = new_birthday.to_json

        expect { instance.update_attributes }.to raise_error(CanCan::AccessDenied)
      end
    end

    context 'without any permission, it' do
      let(:user) { Fabricate(:person) }

      it  'does not expose the existence of the person' do
        expect { instance.update_attributes }.to raise_error(Graphiti::Errors::RecordNotFound)
      end
    end

    it  'does not update write protected attributes' do
      payload[:data][:attributes][:primary_group_id] = 42

      expect { instance.update_attributes }.to raise_error(Graphiti::Errors::InvalidRequest)
    end
  end

  describe 'destroying' do
    let!(:person) { Fabricate(:person) }
    let!(:role) { Fabricate(Group::BottomLayer::Member.name, person: person, group: groups(:bottom_layer_one)) }

    let(:instance) do
      PersonResource.find(id: person.id)
    end

    context 'without any permission, it' do
      let(:user) { Fabricate(:person) }

      it  'does not expose the existence of the person' do
        expect { instance.destroy }.to raise_error(Graphiti::Errors::RecordNotFound)
      end
    end

    context 'without admin privileges' do
      let!(:user_role) { Fabricate(Group::BottomLayer::Leader.name, person: Fabricate(:person), group: groups(:bottom_layer_one)) }
      it 'works' do
        expect {
          expect { instance.destroy }.to raise_error(CanCan::AccessDenied)
        }.not_to change { Person.count }
      end
    end

    context 'with admin privileges' do
      let!(:user_role) { roles(:top_leader) }
      it 'works' do
        expect {
          expect(instance.destroy).to eq(true)
        }.to change { Person.count }.by(-1)
      end
    end
  end

  describe 'sideposting' do
    let!(:user_role) { Fabricate(Group::BottomLayer::Leader.name, group: groups(:bottom_layer_one)) }

    describe 'phone_numbers' do
      describe 'create' do
        let!(:person) { Fabricate(Group::BottomLayer::Member.to_s, group: groups(:bottom_layer_one)).person }

        let(:payload) do
          {
            id: person.id.to_s,
            data: {
              type: 'people',
              id: person.id.to_s,
              attributes: {},
              relationships: {
                phone_numbers: {
                  data: {
                    type: 'phone_numbers',
                    :'temp-id' => 'asdf',
                    method: 'create'
                  }
                }
              }
            },
            included: [
              {
                type: 'phone_numbers',
                :'temp-id' => 'asdf',
                attributes: {
                  label: 'Ds Grosi',
                  number: '0780000000',
                }
              }
            ]
          }
        end

        let(:instance) do
          PersonResource.find(payload)
        end

        it 'works' do
          expect {
            expect(instance.update_attributes).to eq(true), instance.errors.full_messages.to_sentence
          }.to change { PhoneNumber.count }.by(1)

          new_number = PhoneNumber.last
          expect(new_number.contactable).to eq person
          expect(new_number.label).to eq 'Ds Grosi'
          expect(new_number.number).to eq '+41 78 000 00 00'
        end
      end

      describe 'update' do
        let!(:person) { Fabricate(Group::BottomLayer::Member.to_s, group: groups(:bottom_layer_one)).person }
        let!(:phone_number) { Fabricate(:phone_number, contactable: person, number: '0780000000') }

        let(:payload) do
          {
            id: person.id.to_s,
            data: {
              type: 'people',
              id: person.id.to_s,
              attributes: {},
              relationships: {
                phone_numbers: {
                  data: {
                    type: 'phone_numbers',
                    id: phone_number.id.to_s,
                    method: 'update'
                  }
                }
              }
            },
            included: [
              {
                type: 'phone_numbers',
                id: phone_number.id.to_s,
                attributes: {
                  number: '0780000001',
                }
              }
            ]
          }
        end

        let(:instance) do
          PersonResource.find(payload)
        end

        it 'works' do
          expect {
            expect(instance.update_attributes).to eq(true), instance.errors.full_messages.to_sentence
          }.to change { phone_number.reload.number }.to('+41 78 000 00 01')
        end
      end
    end

    describe 'social_accounts' do
      describe 'create' do
        let!(:person) { Fabricate(Group::BottomLayer::Member.to_s, group: groups(:bottom_layer_one)).person }

        let(:payload) do
          {
            id: person.id.to_s,
            data: {
              type: 'people',
              id: person.id.to_s,
              relationships: {
                social_accounts: {
                  data: {
                    type: 'social_accounts',
                    :'temp-id' => 'asdf',
                    method: 'create'
                  }
                }
              }
            },
            included: [
              {
                type: 'social_accounts',
                :'temp-id' => 'asdf',
                attributes: {
                  label: 'Ds Grosi',
                  name: 'ds-grosi'
                }
              }
            ]
          }
        end

        let(:instance) do
          PersonResource.find(payload)
        end

        it 'works' do
          expect {
            expect(instance.update_attributes).to eq(true), instance.errors.full_messages.to_sentence
          }.to change { SocialAccount.count }.by(1)

          new_social_account = SocialAccount.last
          expect(new_social_account.contactable).to eq person
          expect(new_social_account.label).to eq 'Ds Grosi'
          expect(new_social_account.name).to eq 'ds-grosi'
        end
      end

      describe 'update' do
        let!(:person) { Fabricate(Group::BottomLayer::Member.to_s, group: groups(:bottom_layer_one)).person }
        let!(:social_account) { Fabricate(:social_account, contactable: person) }

        let(:payload) do
          {
            id: person.id.to_s,
            data: {
              type: 'people',
              id: person.id.to_s,
              relationships: {
                social_accounts: {
                  data: {
                    type: 'social_accounts',
                    id: social_account.id.to_s,
                    method: 'update'
                  }
                }
              }
            },
            included: [
              {
                type: 'social_accounts',
                id: social_account.id.to_s,
                attributes: {
                  name: 'ds-grosi'
                }
              }
            ]
          }
        end

        let(:instance) do
          PersonResource.find(payload)
        end

        it 'works' do
          expect {
            expect(instance.update_attributes).to eq(true), instance.errors.full_messages.to_sentence
          }.to change { social_account.reload.name }.to('ds-grosi')
        end
      end
    end

    describe 'additional_emails' do
      describe 'create' do
        let!(:person) { Fabricate(Group::BottomLayer::Member.to_s, group: groups(:bottom_layer_one)).person }

        let(:payload) do
          {
            id: person.id.to_s,
            data: {
              type: 'people',
              id: person.id.to_s,
              attributes: {},
              relationships: {
                additional_emails: {
                  data: {
                    type: 'additional_emails',
                    :'temp-id' => 'asdf',
                    method: 'create'
                  }
                }
              }
            },
            included: [
              {
                type: 'additional_emails',
                :'temp-id' => 'asdf',
                attributes: {
                  label: 'Ds Grosi',
                  email: 'ds-grosi@example.com'
                }
              }
            ]
          }
        end

        let(:instance) do
          PersonResource.find(payload)
        end

        it 'works' do
          expect {
            expect(instance.update_attributes).to eq(true), instance.errors.full_messages.to_sentence
          }.to change { AdditionalEmail.count }.by(1)

          new_additional_email = AdditionalEmail.last
          expect(new_additional_email.contactable).to eq person
          expect(new_additional_email.label).to eq 'Ds Grosi'
          expect(new_additional_email.email).to eq 'ds-grosi@example.com'
        end
      end

      describe 'update' do
        let!(:person) { Fabricate(Group::BottomLayer::Member.to_s, group: groups(:bottom_layer_one)).person }
        let!(:additional_email) { Fabricate(:additional_email, contactable: person) }

        let(:payload) do
          {
            id: person.id.to_s,
            data: {
              type: 'people',
              id: person.id.to_s,
              attributes: {},
              relationships: {
                additional_emails: {
                  data: {
                    type: 'additional_emails',
                    id: additional_email.id.to_s,
                    method: 'update'
                  }
                }
              }
            },
            included: [
              {
                type: 'additional_emails',
                id: additional_email.id.to_s,
                attributes: {
                  email: 'ds-grosi@example.com'
                }
              }
            ]
          }
        end

        let(:instance) do
          PersonResource.find(payload)
        end

        it 'works' do
          expect {
            expect(instance.update_attributes).to eq(true), instance.errors.full_messages.to_sentence
          }.to change { additional_email.reload.email }.to 'ds-grosi@example.com'
        end
      end
    end

    describe 'roles' do
      describe 'create' do
        let!(:person) { Fabricate(Group::BottomLayer::Member.to_s, group: groups(:bottom_layer_one)).person }

        let(:payload) do
          {
            id: person.id.to_s,
            data: {
              type: 'people',
              id: person.id.to_s,
              attributes: {},
              relationships: {
                roles: {
                  data: {
                    type: 'roles',
                    :'temp-id' => 'asdf',
                    method: 'create'
                  }
                }
              }
            },
            included: [
              {
                type: 'roles',
                :'temp-id' => 'asdf',
                attributes: {
                }
              }
            ]
          }
        end

        let(:instance) do
          PersonResource.find(payload)
        end

        it 'is disabled for now' do
          expect {
            expect { instance.update_attributes }.to raise_error(Graphiti::Errors::InvalidRequest)
          }.not_to change { Role.count }
        end
      end

      describe 'update' do
        let!(:person) { role.person }
        let!(:role) { Fabricate(Group::BottomLayer::Member.to_s, group: groups(:bottom_layer_one)) }

        let(:payload) do
          {
            id: person.id.to_s,
            data: {
              type: 'people',
              id: person.id.to_s,
              attributes: {},
              relationships: {
                roles: {
                  data: {
                    type: 'roles',
                    id: role.id.to_s,
                    method: 'update'
                  }
                }
              }
            },
            included: [
              {
                type: 'roles',
                id: role.id.to_s,
                attributes: {
                  label: 'provisorisch'
                }
              }
            ]
          }
        end

        let(:instance) do
          PersonResource.find(payload)
        end

        it 'is disabled for now' do
          expect {
            expect { instance.update_attributes }.to raise_error(Graphiti::Errors::InvalidRequest)
          }.not_to change { role.reload.label }
        end
      end
    end
  end
end
