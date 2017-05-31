# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

Hitobito::Application.routes.draw do

  extend LanguageRouteScope

  root to: 'dashboard#index'

  language_scope do

    get '/404', to: 'errors#404'
    get '/500', to: 'errors#500'
    get '/503', to: 'errors#503'

    get '/people/query' => 'person/query#index', as: :query_people
    get '/people/company_name' => 'person/company_name#index', as: :query_company_name
    get '/people/:id' => 'person/top#show', as: :person
    get '/events/:id' => 'event/top#show', as: :event

    resources :groups do
      member do
        get :deleted_subgroups
        get :export_subgroups
        post :reactivate

        get 'merge' => 'group/merge#select'
        post 'merge' => 'group/merge#perform'

        get 'move' => 'group/move#select'
        post 'move' => 'group/move#perform'

      end

      resources :notes, only: [:index, :create, :destroy]

      resources :people, except: [:new, :create] do
        member do
          post :send_password_instructions
          put :primary_group

          get 'history' => 'person/history#index'
          get 'log' => 'person/log#index'
          get 'colleagues' => 'person/colleagues#index'
        end

        resources :notes, only: [:create, :destroy]
        resources :qualifications, only: [:new, :create, :destroy]
        get 'qualifications' => 'qualifications#new' # route required for language switch

        scope module: 'person' do
          post 'tags' => 'tags#create'
          delete 'tags' => 'tags#destroy'
          get 'tags/query' => 'tags#query'
        end
      end

      resources :roles, except: [:index, :show] do
        collection do
          get :details
          get :role_types
        end
      end
      get 'roles' => 'roles#new' # route required for language switch
      get 'roles/:id' => 'roles#edit' # route required for language switch

      resources :people_filters, only: [:new, :create, :destroy] do
        collection do
          get 'qualification'
        end
      end
      get 'people_filters' => 'people_filters#new' # route required for language switch


      get 'deleted_people' => 'group/deleted_people#index'

      get 'person_add_requests' => 'group/person_add_requests#index', as: :person_add_requests
      post 'person_add_requests' => 'group/person_add_requests#activate'
      delete 'person_add_requests' => 'group/person_add_requests#deactivate'

      put 'person_add_request_ignored_approvers' =>
            'group/person_add_request_ignored_approvers#update',
          as: 'person_add_request_ignored_approvers'

      resources :events do
        collection do
          get 'simple' => 'events#index'
          get 'course' => 'events#index', type: 'Event::Course'
        end

        scope module: 'event' do

          member do
            get  'register' => 'register#index'
            post 'register' => 'register#check'
            put  'register' => 'register#register'
          end

          resources :application_market, only: :index do
            member do
              put    'waiting_list' => 'application_market#put_on_waiting_list'
              delete 'waiting_list' => 'application_market#remove_from_waiting_list'
              put    'participant' => 'application_market#add_participant'
              delete 'participant' => 'application_market#remove_participant'
            end
          end

          resources :applications, only: [] do
            member do
              put    :approve
              delete :reject
            end
          end

          resources :attachments, only: [:create, :destroy]

          resources :participations do
            get 'print', on: :member
          end

          resources :roles, except: [:index, :show]
          get 'roles' => 'roles#new' # route required for language switch
          get 'roles/:id' => 'roles#edit' # route required for language switch

          resources :qualifications, only: [:index, :update, :destroy]

        end

      end

      resources :mailing_lists do
        resources :subscriptions, only: [:index, :destroy] do
          collection do
            resources :person, only: [:new, :create], controller: 'subscriber/person'
            get 'person' => 'subscriber/person#new' # route required for language switch

            resources :exclude_person, only: [:new, :create], controller: 'subscriber/exclude_person'
            get 'exclude_person' => 'subscriber/exclude_person#new' # route required for language switch

            resources :group, only: [:new, :create], controller: 'subscriber/group' do
              collection do
                get :query
                get :roles
              end
            end
            get 'group' => 'subscriber/group#new' # route required for language switch

            resources :event, only: [:new, :create], controller: 'subscriber/event' do
              collection do
                get :query
              end
            end
            get 'event' => 'subscriber/event#new' # route required for language switch

            resource :user, only: [:create, :destroy], controller: 'subscriber/user'
          end
        end
      end

      resource :csv_imports, only: [:new, :create], controller: 'person/csv_imports' do
        member do
          post :define_mapping
          post :preview
          get 'define_mapping' => 'person/csv_imports#new' # route required for language switch
          get 'preview'        => 'person/csv_imports#new' # route required for language switch
        end
      end

    end # resources :group

    get 'list_courses' => 'event/lists#courses', as: :list_courses
    get 'list_events' => 'event/lists#events', as: :list_events

    get 'full' => 'full_text#index'
    get 'query' => 'full_text#query'

    resources :event_kinds, module: 'event', controller: 'kinds'

    resources :qualification_kinds

    resources :label_formats do
      collection do
        resource :settings, controller: 'label_format/settings', as: 'label_format_settings'
      end
    end

    resources :custom_contents, only: [:index, :edit, :update]
    get 'custom_contents/:id' => 'custom_contents#edit'

    devise_for :people, skip: [:registrations], path: "users"
    as :person do
      get 'users/edit' => 'devise/registrations#edit', :as => 'edit_person_registration'
      put 'users' => 'devise/registrations#update', :as => 'person_registration'
      get 'users' => 'devise/registrations#edit' # route required for language switch

      post 'users/token' => 'devise/tokens#create'
      delete 'users/token' => 'devise/tokens#destroy'
    end

    post 'person_add_requests/:id' => 'person/add_requests#approve', as: :person_add_request
    delete 'person_add_requests/:id' => 'person/add_requests#reject'

    get 'changelog' => 'changelog#index'

  end # scope locale

  # The priority is based upon order of creation:
  # first created -> highest priority.

  # See how all your routes lay out with "rake routes"
end
