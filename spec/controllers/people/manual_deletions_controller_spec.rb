# frozen_string_literal: true

#  Copyright (c) 2023, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe People::ManualDeletionsController do
  let(:bottom_leader) { Fabricate(Group::BottomLayer::Leader.sti_name.to_sym, group: bottom_layer).person }
  let(:bottom_member) { people(:bottom_member) }
  let(:bottom_layer) { groups(:bottom_layer_one) }
  let!(:person_with_expired_roles) { Fabricate(Group::BottomGroup::Member.name.to_sym,
                                              group: groups(:bottom_group_one_one),
                                              created_at: 11.months.ago,
                                              deleted_at: 10.months.ago).person }

  before { sign_in(user) }

  describe 'GET #show' do
    def get_show
      get :show, xhr: true, params: { group_id: bottom_layer.id, person_id: person_with_expired_roles.id }, format: :js
    end

    context 'with feature disabled' do
      before do
        allow(Settings.people.manual_deletion).to receive(:enabled).and_return(false)
      end

      context 'as member' do
        let(:user) { bottom_member }

        it 'is disabled' do
          expect do
            get_show
          end.to raise_error(CanCan::AccessDenied)
        end
      end

      context 'as leader' do
        let(:user) { bottom_leader }

        it 'is disabled' do
          expect do
            get_show
          end.to raise_error(CanCan::AccessDenied)
        end
      end
    end

    context 'with feature enabled' do
      before do
        allow(Settings.people.manual_deletion).to receive(:enabled).and_return(true)
      end

      context 'as member' do
        let(:user) { bottom_member }

        it 'is unauthorized' do
          expect do
            get_show
          end.to raise_error(CanCan::AccessDenied)
        end
      end

      context 'as leader' do
        let(:user) { bottom_leader }

        it 'is disabled' do
          get_show
          expect(response).to be_successful
          expect(response).to render_template 'people/manual_deletions/show'
        end
      end
    end
  end

  describe 'POST #minimize' do
    context 'with feature disabled' do
      before do
        allow(Settings.people.manual_deletion).to receive(:enabled).and_return(false)
      end

      context 'as member' do
        let(:user) { bottom_member }

        it 'is disabled' do
          expect do
            post :minimize, params: { group_id: bottom_layer.id, person_id: person_with_expired_roles.id }
          end.to raise_error(CanCan::AccessDenied)
        end
      end

      context 'as leader' do
        let(:user) { bottom_leader }

        it 'is disabled' do
          expect do
            post :minimize, params: { group_id: bottom_layer.id, person_id: person_with_expired_roles.id }
          end.to raise_error(CanCan::AccessDenied)
        end
      end
    end

    context 'with feature enabled' do
      before do
        allow(Settings.people.manual_deletion).to receive(:enabled).and_return(true)
      end

      context 'as member' do
        let(:user) { bottom_member }

        it 'is unauthorized' do
          expect do
            post :minimize, params: { group_id: bottom_layer.id, person_id: person_with_expired_roles.id }
          end.to raise_error(CanCan::AccessDenied)
        end
      end

      context 'as leader' do
        let(:user) { bottom_leader }

        it 'minimizes' do
          expect(person_with_expired_roles.minimized_at).to be_nil

          post :minimize, params: { group_id: bottom_layer.id, person_id: person_with_expired_roles.id }

          person_with_expired_roles.reload

          expect(person_with_expired_roles.minimized_at).to be_present
          expect(flash[:notice]).to eq("#{person_with_expired_roles.full_name} wurde erfolgreich minimiert.")
        end

        context 'with recent event participation' do
          before do
            event = Fabricate(:event, dates: [Event::Date.new(start_at: 10.days.ago)])
            Event::Participation.create!(event: event, person: person_with_expired_roles)
          end

          it 'does not minimize' do
            expect do
              post :minimize, params: { group_id: bottom_layer.id, person_id: person_with_expired_roles.id }
            end.to raise_error(StandardError)
          end
        end

        context 'with old event participation' do
          before do
            event = Fabricate(:event, dates: [Event::Date.new(start_at: 12.years.ago)])
            Event::Participation.create!(event: event, person: person_with_expired_roles)
          end

          it 'minimizes' do
            expect(person_with_expired_roles.minimized_at).to be_nil

            post :minimize, params: { group_id: bottom_layer.id, person_id: person_with_expired_roles.id }

            person_with_expired_roles.reload

            expect(person_with_expired_roles.minimized_at).to be_present
            expect(flash[:notice]).to eq("#{person_with_expired_roles.full_name} wurde erfolgreich minimiert.")
          end
        end

        context 'when already minimized' do
          before do
            person_with_expired_roles.update!(minimized_at: Time.zone.now)
          end

          it 'does not minimize' do
            expect do
              post :minimize, params: { group_id: bottom_layer.id, person_id: person_with_expired_roles.id }
            end.to raise_error(StandardError)
          end
        end
      end
    end
  end

  describe 'POST #delete' do
    context 'with feature disabled' do
      before do
        allow(Settings.people.manual_deletion).to receive(:enabled).and_return(false)
      end

      context 'as member' do
        let(:user) { bottom_member }

        it 'is disabled' do
          expect do
            post :delete, params: { group_id: bottom_layer.id, person_id: person_with_expired_roles.id }
          end.to raise_error(CanCan::AccessDenied)
        end
      end

      context 'as leader' do
        let(:user) { bottom_leader }

        it 'is disabled' do
          expect do
            post :delete, params: { group_id: bottom_layer.id, person_id: person_with_expired_roles.id }
          end.to raise_error(CanCan::AccessDenied)
        end
      end
    end

    context 'with feature enabled' do
      before do
        allow(Settings.people.manual_deletion).to receive(:enabled).and_return(true)
      end

      context 'as member' do
        let(:user) { bottom_member }

        it 'is unauthorized' do
          expect do
            post :delete, params: { group_id: bottom_layer.id, person_id: person_with_expired_roles.id }
          end.to raise_error(CanCan::AccessDenied)
        end
      end

      context 'as leader' do
        let(:user) { bottom_leader }

        it 'deletes' do
          expect do
            post :delete, params: { group_id: bottom_layer.id, person_id: person_with_expired_roles.id }
          end.to change { Person.count }.by(-1)
        end

        context 'with recent event participation' do
          before do
            event = Fabricate(:event, dates: [Event::Date.new(start_at: 10.days.ago)])
            Event::Participation.create!(event: event, person: person_with_expired_roles)
          end

          it 'does not delete' do
            expect do
              post :delete, params: { group_id: bottom_layer.id, person_id: person_with_expired_roles.id }
            end.to raise_error(StandardError)
          end
        end

        context 'with old event participation' do
          before do
            event = Fabricate(:event, dates: [Event::Date.new(start_at: 12.years.ago)])
            Event::Participation.create!(event: event, person: person_with_expired_roles)
          end

          it 'deletes' do
            expect do
              post :delete, params: { group_id: bottom_layer.id, person_id: person_with_expired_roles.id }
            end.to change { Person.count }.by(-1)
          end
        end
      end
    end
  end
end
