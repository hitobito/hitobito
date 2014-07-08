# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

Hitobito::Application.routes.draw do

  extend LanguageRouteScope

  root :to => 'dashboard#index'

  language_scope do

    get '/404', to: 'errors#404'
    get '/500', to: 'errors#500'
    get '/503', to: 'errors#503'

    resources :people, only: :show do
      collection do
        get :query
      end
    end

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

      resources :people, except: [:new, :create] do
        member do
          get :history
          get :log
          post :send_password_instructions
          put :primary_group
        end
        resources :qualifications, only: [:new, :create, :destroy]
        get 'qualifications' => 'qualifications#new' # route required for language switch
      end

      resources :roles, except: [:index, :show] do
        collection do
          get :details
          get :role_types
        end
      end
      get 'roles' => 'roles#new' # route required for language switch
      get 'roles/:id' => 'roles#edit' # route required for language switch

      resources :people_filters, only: [:new, :create, :destroy]
      get 'people_filters' => 'people_filters#new' # route required for language switch

      resources :events do
        collection do
          get 'simple' => 'events#index'
          get 'course' => 'events#index', type: 'Event::Course'
        end

        scope module: 'event' do
          resources :participations do
            get 'print', on: :member
          end

          resources :roles

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

          resources :qualifications, only: [:index, :update, :destroy]

          member do
            get  'register' => 'register#index'
            post 'register' => 'register#check'
            put  'register' => 'register#register'
          end
        end

      end

      resources :mailing_lists do
        resources :subscriptions, only: [:index, :destroy] do
          collection do
            resources :person, only: [:new, :create], controller: 'subscriber/person'
            resources :exclude_person, only: [:new, :create], controller: 'subscriber/exclude_person'
            resources :group, only: [:new, :create], controller: 'subscriber/group' do
              collection do
                get :query
                get :roles
              end
            end
            resources :event, only: [:new, :create], controller: 'subscriber/event' do
              collection  do
                get :query
              end
            end
            resource :user, only: [:create, :destroy], controller: 'subscriber/user'
          end
        end
      end

      resource :csv_imports, only: [:new, :create] do
        member do
          post :define_mapping
          post :preview
          get 'define_mapping' => 'csv_imports#new' # route required for language switch
          get 'preview'        => 'csv_imports#new' # route required for language switch
        end
      end

    end

    get 'list_courses' => 'event/lists#courses', as: :list_courses
    get 'list_events' => 'event/lists#events', as: :list_events

    get 'full' => 'full_text#index'
    get 'query' => 'full_text#query'

    resources :event_kinds, module: 'event', controller: 'kinds'

    resources :qualification_kinds

    resources :label_formats

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

  end # scope locale

  # The priority is based upon order of creation:
  # first created -> highest priority.

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id))(.:format)'
end
