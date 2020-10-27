# frozen_string_literal: true

Hitobito::Application.routes.draw do

  extend LanguageRouteScope

  root to: 'dashboard#index'

  get '/healthz', to: 'healthz#show'
  get '/healthz/mail', to: 'healthz/mail#show'

  use_doorkeeper_openid_connect
  use_doorkeeper do # we only use tokens and authorizations
    skip_controllers :applications, :token_info, :authorized_applications
  end

  language_scope do
    namespace :oauth do
      resource :profile, only: :show
      resources :applications do
        resources :access_grants, only: :index
        resources :access_tokens, only: :index
      end
      resources :access_grants, only: :destroy
      resources :access_tokens, only: :destroy
      resources :active_authorizations, only: [:index, :destroy]
    end

    %w(404 500 503).each do |code|
      get code, to: 'errors#show', code: code
    end

    get '/people/query' => 'person/query#index', as: :query_people
    get '/people/query_household' => 'person/query_household#index', as: :query_household
    get '/people/company_name' => 'person/company_name#index', as: :query_company_name
    get '/people/:id' => 'person/top#show', as: :person
    get '/events/:id' => 'event/top#show', as: :event

    get 'list_groups' => 'group/lists#index', as: :list_groups

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

      resource :invoice_list, except: [:edit]
      resource :invoice_config, only: [:edit, :show, :update]

      resources :invoices do
        resources :payments, only: :create
      end
      resources :invoice_articles

      resource :payment_process, only: [:new, :show, :create]
      resources :notes, only: [:index, :create, :destroy]

      resources :people, except: [:new, :create] do

        member do
          post :send_password_instructions
          put :primary_group

          get 'history' => 'person/history#index'
          get 'log' => 'person/log#index'
          get 'colleagues' => 'person/colleagues#index'
          get 'invoices' => 'person/invoices#index'

        end

        resources :notes, only: [:create, :destroy]
        resources :qualifications, only: [:new, :create, :destroy]
        get 'qualifications' => 'qualifications#new' # route required for language switch

        scope module: 'person' do
          resources :subscriptions, only: [:index, :create, :destroy]
          post 'tags' => 'tags#create'
          delete 'tags' => 'tags#destroy'
          get 'tags/query' => 'tags#query'
          post 'impersonate' => 'impersonation#create'
          delete 'impersonate' => 'impersonation#destroy'
          get 'households' => 'households#new'
        end

      end

      resource :tag_list, only: [:destroy, :create, :new] do
        get 'deletable' => 'tag_lists#deletable'
      end

      resource :role_list, only: [:destroy, :create, :new] do
        get 'deletable' => 'role_lists#deletable'
        get 'move'      => 'role_lists#move'
        get 'movable'   => 'role_lists#movable'
        put 'move'      => 'role_lists#update'
      end
      resources :roles, except: [:index, :show] do
        collection do
          get :details
          get :role_types
        end
      end
      get 'roles' => 'roles#new' # route required for language switch
      get 'roles/:id' => 'roles#edit' # route required for language switch

      resources :people_filters, only: [:new, :create, :edit, :update, :destroy]
      get 'people_filters' => 'people_filters#new' # route required for language switch


      get 'deleted_people' => 'group/deleted_people#index'

      get 'person_add_requests' => 'group/person_add_requests#index', as: :person_add_requests
      post 'person_add_requests' => 'group/person_add_requests#activate'
      delete 'person_add_requests' => 'group/person_add_requests#deactivate'

      put 'person_add_request_ignored_approvers' =>
            'group/person_add_request_ignored_approvers#update',
          as: 'person_add_request_ignored_approvers'

      get 'public_events/:id' => 'public_events#show', as: :public_event
      get 'events/participation_lists/new' => 'event/participation_lists#new'

      resources :events do
        collection do
          get 'simple' => 'events#index'
          get 'course' => 'events#index', type: 'Event::Course'
          get 'typeahead' => 'events#typeahead'
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

          resource :participation_lists, only: :create
          resources :participations do
            collection do
              get 'contact_data', controller: 'participation_contact_datas', action: 'edit'
              post 'contact_data', controller: 'participation_contact_datas', action: 'update'
            end
            member do
              get 'print'
            end
          end

          resources :roles, except: [:index, :show]
          get 'roles' => 'roles#new' # route required for language switch
          get 'roles/:id' => 'roles#edit' # route required for language switch

          get 'qualifications' => 'qualifications#index'
          put 'qualifications' => 'qualifications#update'
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

        resources :mailchimp_synchronizations, only: [:create]

        resources :mail_logs, only: [:index], controller: 'mailing_list/mail_logs'
      end

      resource :csv_imports, only: [:new, :create], controller: 'person/csv_imports' do
        member do
          post :define_mapping
          post :preview
          get 'define_mapping' => 'person/csv_imports#new' # route required for language switch
          get 'preview'        => 'person/csv_imports#new' # route required for language switch
        end
      end

      resources :service_tokens

    end # resources :group

    get 'list_courses' => 'event/lists#courses', as: :list_courses
    get 'list_events' => 'event/lists#events', as: :list_events

    get 'full' => 'full_text#index'
    get 'query' => 'full_text#query'

    resources :event_kinds, module: 'event', controller: 'kinds'

    resources :qualification_kinds
    resources :tags do
      collection do
        get 'merge' => 'tags/merge#new', as: 'new_merge'
        post 'merge' => 'tags/merge#create', as: 'merge'
      end
    end

    resources :label_formats do
      collection do
        resource :settings, controller: 'label_format/settings', as: 'label_format_settings'
      end
    end

    resources :custom_contents, only: [:index, :edit, :update]
    get 'custom_contents/:id' => 'custom_contents#edit'

    resource :event_feed, only: [:show, :update]
    resources :help_texts, except: [:show]

    devise_for :service_tokens, only: [:sessions]
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

    get 'downloads/:id' => 'async_downloads#show'
    get 'downloads/:id/exists' => 'async_downloads#exists?'

    get 'synchronizations/:id' => 'async_synchronizations#show'

    resources :table_displays, only: [:create]

  end # scope locale

  # The priority is based upon order of creation:
  # first created -> highest priority.

  # See how all your routes lay out with "rake routes"
end
