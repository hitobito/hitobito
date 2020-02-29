# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe FullTextController, type: :controller do

  before { sign_in(people(:top_leader)) }

  [SearchStrategies::Sphinx, SearchStrategies::Sql].each do |strategy|

    context strategy.name.demodulize.downcase do
      before do
        [[:list_people, Person.where(id: people(:bottom_member).id)],
         [:query_people, Person.where(id: people(:bottom_member).id)],
         [:query_groups, Group.where(id: groups(:bottom_layer_one).id)],
         [:query_events, Event.where(id: events(:top_course).id)]].each do |stub, value|
          allow_any_instance_of(strategy).to receive(stub).and_return(value)
        end

        allow(Hitobito::Application).to receive(:sphinx_present?)
          .and_return(strategy == SearchStrategies::Sphinx)
      end

      describe 'GET index' do

        before do
          sign_in(people(:top_leader))
        end

        it 'uses correct search strategy' do
          get :index, q: 'Bottom'
          expect(assigns(:search_strategy).class).to eq(strategy)
        end

        it 'finds person' do
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

        it 'uses correct search strategy' do
          get :query, q: 'Bottom'
          expect(assigns(:search_strategy).class).to eq(strategy)
        end

        it 'finds person' do
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

      end
    end

    describe strategy.name.demodulize.downcase + ' active tab' do

      it 'displays people tab' do
        allow(@controller.send :search_strategy).to receive(:list_people).and_return(Person.where(id: people(:bottom_member).id))
        get :index, q: 'query with people results'
        expect(assigns(:active_tab)).to eq(:people)
      end

      it 'displays groups tab' do
        allow(@controller.send :search_strategy).to receive(:query_groups).and_return(Group.where(id: groups(:bottom_layer_one).id))
        get :index, q: 'query with group results'
        expect(assigns(:active_tab)).to eq(:groups)
      end

      it 'displays events tab' do
        allow(@controller.send :search_strategy).to receive(:query_events).and_return(Event.where(id: events(:top_course).id))
        get :index, q: 'query with event results'
        expect(assigns(:active_tab)).to eq(:events)
      end

      it 'displays people tab by default' do
        get :index, q: 'query with no results'
        expect(assigns(:active_tab)).to eq(:people)
      end

    end

  end

end
