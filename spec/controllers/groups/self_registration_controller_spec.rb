# frozen_string_literal: true

#  Copyright (c) 2021, Efficiency-Club Bern. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Groups::SelfRegistrationController do

  let(:group) { groups(:top_group) }
  let(:person) { people(:top_leader) }

  context 'with feature disabled' do
    before do
      group.update!(self_registration_role_type: Group::TopGroup::Member.sti_name)
      allow(Settings.groups.self_registration).to receive(:enabled).and_return(false)
    end

    describe 'GET new' do
      it 'redirects to group' do
        sign_in(person)

        get :new, params: { group_id: group.id }

        is_expected.to redirect_to(group_path(group.id))
      end
    end

    describe 'POST create' do
      it 'redirects to group' do
        sign_in(person)

        post :create, params: {
          group_id: group.id,
          new_person: { email: 'foo@example.com' }
        }

        is_expected.to redirect_to(group_path(group.id))
      end
    end
  end

  context 'with feature enabled' do
    before do
      allow(Settings.groups.self_registration).to receive(:enabled).and_return(true)
    end

    context 'GET new' do
      context 'when registration active' do

        before do
          group.update(self_registration_role_type: Group::TopGroup::Member.sti_name)
        end

        context 'when unautorized' do
          it 'renders page' do
            get :new, params: { group_id: group.id }

            is_expected.to render_template('groups/self_registration/new')
          end
        end

        context 'when authorized' do
          it 'redirects to group' do
            sign_in(person)

            get :new, params: { group_id: group.id }

            is_expected.to redirect_to(group_path(group.id))
          end
        end
      end

      context 'when registration is inactive' do
        it 'redirects to group' do
          sign_in(person)

          get :new, params: { group_id: group.id }

          is_expected.to redirect_to(group_path(group.id))
        end
      end
    end

    context 'POST create' do
      context 'when registration active' do

        before do
          group.update!(self_registration_role_type: Group::TopGroup::Member.sti_name)
        end

        it 'redirects to login if honeypot filled' do
          post :create, params: {
            group_id: group.id,
            verification: 'foo',
            new_person: { email: 'foo@example.com' }
          }

          is_expected.to redirect_to(new_person_session_path)
        end

        it 'creates person and role' do
          expect do
            post :create, params: {
              group_id: group.id,
              role: {
                group_id: group.id,
                new_person: { first_name: 'Bob', last_name: 'Miller' }
              }
            }
          end.to change { Person.count }.by(1)
            .and change { Role.count }.by(1)
            .and change { ActionMailer::Base.deliveries.count }.by(0)

          person = Person.find_by(first_name: 'Bob', last_name: 'Miller')
          role = person.roles.first

          expect(person.primary_group).to eq(group)
          expect(person.full_name).to eq('Bob Miller')
          expect(role.type).to eq(Group::TopGroup::Member.sti_name)
          expect(role.group).to eq(group)

          is_expected.to redirect_to(new_person_session_path)
        end

        it 'does not send any emails when no email provided' do
          expect do
            post :create, params: {
                group_id: group.id,
                role: {
                    group_id: group.id,
                    new_person: { first_name: 'Bob', last_name: 'Miller' }
                }
            }
          end.not_to change { ActionMailer::Base.deliveries.count }
        end

        it 'sends password reset instructions' do
          expect do
            post :create, params: {
                group_id: group.id,
                role: {
                    group_id: group.id,
                    new_person: { first_name: 'Bob', last_name: 'Miller', email: 'foo@example.com' }
                }
            }
          end.to change { ActionMailer::Base.deliveries.count }.by(1)
        end

        it 'sends notification mail' do
          group.update(self_registration_notification_email: 'notification@example.com')

          expect do
            post :create, params: {
                group_id: group.id,
                role: {
                    group_id: group.id,
                    new_person: { first_name: 'Bob', last_name: 'Miller' }
                }
            }
          end.to change { ActionMailer::Base.deliveries.count }.by(1)
        end
      end
    end
  end
end
