# frozen_string_literal: true

# Copyright (c) 2012-2022, Hitobito AG. This file is part of
# hitobito and licensed under the Affero General Public License version 3
# or later. See the COPYING file at the top-level directory or at
# https://github.com/hitobito/hitobito.

require 'spec_helper'

describe HitobitoLogEntriesController do
  before { sign_in(user) }

  describe 'GET #index' do
    context 'without admin permissions' do
      let(:user) { people(:bottom_member) }

      it 'denies access' do
        expect { get :index }.to raise_error(CanCan::AccessDenied)
      end
    end

    context 'with admin permissions' do
      let(:user) { people(:top_leader) }

      it 'returns entries' do
        get :index
        expect(assigns(:hitobito_log_entries)).to match_array(HitobitoLogEntry.all)
      end

      it 'filters by level' do
        get :index, params: {level: 'warn'}
        expect(assigns(:hitobito_log_entries)).to match_array(hitobito_log_entries(:error_webhook, :error_ebics))
      end

      it 'filters by from_time' do
        travel_to(2.days.ago.midday) do
          # from_date_param = 2.days.ago.to_date.to_s(:db)
          get :index, params: {from_time: '07:00'}
          expect(assigns(:hitobito_log_entries)).
            to match_array(hitobito_log_entries(:error_webhook, :error_ebics, :entry_with_payload))
        end
      end

      it 'filters by from_date' do
        travel_to(Time.now.midday) do
          from_date_param = 2.days.ago.to_date.to_s(:db)
          get :index, params: {from_date: from_date_param}
          expect(assigns(:hitobito_log_entries))
            .to match_array(hitobito_log_entries(:error_webhook, :error_ebics, :entry_with_payload))
        end
      end

      it 'filters by from_date and from_time' do
        travel_to(Time.now.midday) do
          from_date_param = 2.days.ago.to_date.to_s(:db)
          get :index, params: {from_date: from_date_param, from_time: '18:00' }
          expect(assigns(:hitobito_log_entries))
            .to match_array(hitobito_log_entries(:error_ebics, :entry_with_payload))
        end
      end

      it 'filters by to_time' do
        travel_to(2.days.ago.midday) do
          # from_date_param = 2.days.ago.to_date.to_s(:db)
          get :index, params: {to_time: '07:00'}
          expect(assigns(:hitobito_log_entries)).to match_array(hitobito_log_entries(:debug_webhook, :info_webhook, :info_mail))
        end
      end

      it 'filters by to_date' do
        travel_to(Time.now.midday) do
          to_date_param = 3.days.ago.to_date.to_s(:db)
          get :index, params: {to_date: to_date_param}
          expect(assigns(:hitobito_log_entries)).to match_array(hitobito_log_entries(:debug_webhook, :info_webhook, :info_mail))
        end
      end

      it 'filters by to_date and to_time' do
        travel_to(Time.now.midday) do
          to_date_param = 3.days.ago.to_date.to_s(:db)
          get :index, params: {to_date: to_date_param, to_time: '07:00' }
          expect(assigns(:hitobito_log_entries)).to match_array(hitobito_log_entries(:debug_webhook, :info_webhook))
        end
      end

      it 'filters by from and to date/time' do
        travel_to(Time.now.midday) do
          from_date_param = 3.days.ago.to_date.to_s(:db)
          to_date_param = 1.days.ago.to_date.to_s(:db)
          get :index, params: {from_date: from_date_param, from_time: '10:00', to_date: to_date_param, to_time: '07:00' }
          expect(assigns(:hitobito_log_entries)).to match_array(hitobito_log_entries(:error_webhook, :info_mail))
        end
      end

      HitobitoLogger.categories.each do |category|
        context "/#{category}" do
          it 'filters by category' do
            entries = HitobitoLogEntry.where(category: category)
            expect(entries).to be_present # make sure we actually have test objects

            get :index, params: {category: category}
            expect(assigns(:hitobito_log_entries)).to match_array(entries)
          end
        end
      end
    end
  end
end
