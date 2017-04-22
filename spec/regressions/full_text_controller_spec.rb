# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe FullTextController, :mysql, type: :controller do

  context 'sphinx' do
    sphinx_environment(:people, :groups, :events) do
      before do
        Rails.cache.clear
        index_sphinx
      end

      describe 'GET index' do

        before { sign_in(people(:top_leader)) }

        it 'finds accessible person' do
          get :index, q: 'Bottom'

          expect(assigns(:people)).to include(people(:bottom_member))
        end

        context 'without any params' do
          it 'returns nothing' do
            get :index

            expect(@response).to be_ok
            expect(assigns(:people)).to eq([])
          end
        end

      end

      describe 'GET query' do

        before { sign_in(people(:top_leader)) }

        it 'finds accessible person' do
          get :query, q: 'Bottom'

          expect(@response.body).to include(people(:bottom_member).full_name)
        end

        it 'finds groups' do
          get :query, q: groups(:bottom_layer_one).to_s[1..5]

          expect(@response.body).to include(groups(:bottom_layer_one).to_s)
        end

        it 'finds events' do
          get :query, q: events(:top_course).to_s[1..5]
          expect(@response.body).to include(events(:top_course).to_s)
        end

        context 'without any params' do
          it 'returns nothing' do
            get :query

            expect(@response).to be_ok
            expect(JSON.parse(@response.body)).to eq([])
          end
        end

      end
    end
  end

  context 'sql' do
    describe 'GET index' do

      before { sign_in(people(:top_leader)) }

      it 'finds accessible person' do
        get :index, q: 'Bottom'

        expect(assigns(:people)).to include(people(:bottom_member))
      end

      context 'without any params' do
        it 'returns nothing' do
          get :index

          expect(@response).to be_ok
          expect(assigns(:people)).to eq([])
        end
      end

    end

    describe 'GET query' do

      before { sign_in(people(:top_leader)) }

      it 'finds accessible person' do
        get :query, q: 'Bottom'

        expect(@response.body).to include(people(:bottom_member).full_name)
      end

      it 'finds groups' do
        get :query, q: groups(:bottom_layer_one).to_s[1..5]

        expect(@response.body).to include(groups(:bottom_layer_one).to_s)
      end

      it 'finds events' do
        get :query, q: events(:top_course).to_s[1..5]
        expect(@response.body).to include(events(:top_course).to_s)
      end

      context 'without any params' do
        it 'returns nothing' do
          get :query

          expect(@response).to be_ok
          expect(JSON.parse(@response.body)).to eq([])
        end
      end

    end

  end

end
