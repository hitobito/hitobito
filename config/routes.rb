# frozen_string_literal: true

#  Copyright (c) 2012-2023, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

Hitobito::Application.routes.draw do

  extend LanguageRouteScope

  root to: 'dashboard#index'

  get '/healthz', to: 'healthz#show'
  get '/healthz/mail', to: 'healthz/mail#show'
  get '/healthz/truemail', to: 'healthz#show'

  use_doorkeeper_openid_connect

  # custom oidc RP logout
  # https://openid.net/specs/openid-connect-rpinitiated-1_0.html#RPLogout
  get '/oidc/logout', to: 'doorkeeper/hitobito/oidc_sessions#destroy'
  post '/oidc/logout', to: 'doorkeeper/hitobito/oidc_sessions#destroy'

  use_doorkeeper do # we only use tokens and authorizations
    skip_controllers :applications, :token_info, :authorized_applications
  end

  get '/verify_membership/:verify_token' => 'people/membership/verify#show', as: 'verify_membership'

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
      get code, to: "errors#show#{code}"
    end

    get '/blocked' => 'blocked#index', as: :blocked

    get '/addresses/query' => 'addresses#query'

    get '/people/query' => 'person/query#index', as: :query_people
    get '/people/query_household/(:person_id)' => 'person/query_household#index',
        as: :query_household
    get '/people/company_name' => 'person/company_name#index', as: :query_company_name
    get '/people/:id' => 'person/top#show', as: :person
    get '/events/:id' => 'event/top#show', as: :event
    get '/invoices/:id' => 'invoices/top#show', as: :invoices

    get 'list_groups' => 'group/lists#index', as: :list_groups

    resources :groups do
      scope module: 'subscriber' do
        resource :subscriber_list, only: [:new] do
          get 'typeahead' => 'subscriber_lists#typeahead'
        end
      end
      member do
        get :deleted_subgroups
        get :export_subgroups
        post :reactivate

        get 'merge' => 'group/merge#select'
        post 'merge' => 'group/merge#perform'

        get 'move' => 'group/move#select'
        post 'move' => 'group/move#perform'

        post 'archive' => 'group/archive#create'
      end

      get 'self_registration' => 'groups/self_registration#show'
      post 'self_registration' => 'groups/self_registration#create'

      get 'self_inscription' => 'groups/self_inscription#show'
      post 'self_inscription' => 'groups/self_inscription#create'

      FeatureGate.if('groups.statistics') do
        resources :statistics, only: [:index], module: :group
      end

      get 'log' => 'group/log#index'

      resources :payments, only: :index
      resources :invoices do
        resources :payments, only: :create
        collection do
          resource :evaluations, only: [:show], module: :invoices, as: 'invoices_evaluations'
          resources :by_article, only: [:index], module: :invoices, as: 'invoices_by_article'
          resources :recalculate, only: [:new], module: :invoices, as: 'recalculate'
        end
      end
      resources :invoice_articles
      resource :invoice_config, only: [:edit, :show, :update]

      resources :payment_provider_configs, only: [] do
        member do
          get 'ini_letter' => 'payment_provider_configs/ini_letter#show'
        end
      end

      resource :invoice_list, except: [:edit, :show]
      resources :invoice_lists, only: [:index] do
        resource :destroy, only: [:show, :destroy], module: :invoice_lists,
                           as: 'invoice_lists_destroy'
        resources :invoices, only: [:index]
      end
      resource :payment_process, only: [:new, :show, :create]

      resources :notes, only: [:index, :create, :destroy]

      resources :people, except: [:new, :create] do
        resource :household, except: [:new, :create]

        scope module: 'people' do
          resource :manual_deletion, only: [:show] do
            post :minimize
            post :delete
          end
        end

        member do
          post :send_password_instructions
          put :primary_group

          post 'totp_reset' => 'people/totp_reset#create', as: 'totp_reset'
          post 'totp_disable' => 'people/totp_disable#create', as: 'totp_disable'
          post 'password_override' => 'person/security_tools#password_override'
          post 'block' => 'person/security_tools#block_person'
          post 'unblock' => 'person/security_tools#unblock_person'

          get 'history' => 'person/history#index'
          get 'log' => 'person/log#index'
          get 'security_tools' => 'person/security_tools#index'
          get 'colleagues' => 'person/colleagues#index'
          get 'personal_invoices' => 'person/invoices#index'
          get 'messages' => 'person/messages#index'
        end

        resources :notes, only: [:create, :destroy]
        resources :qualifications, only: [:new, :create, :destroy]
        get 'qualifications' => 'qualifications#new' # route required for language switch

        resources :assignments, only: [:show, :edit, :update]
        scope module: 'person' do
          resources :assignments, only: [:index]
          resources :subscriptions, only: [:index, :create, :destroy]
          post 'tags' => 'tags#create'
          delete 'tags' => 'tags#destroy'
          get 'tags/query' => 'tags#query'
          post 'impersonate' => 'impersonation#create'
          delete 'impersonate' => 'impersonation#destroy'
        end
      end

      resources :person_duplicates, only: [:index] do
        member do
          get 'merge' => 'person_duplicates/merge#new', as: 'new_merge'
          post 'merge' => 'person_duplicates/merge#create', as: 'merge'
          get 'ignore' => 'person_duplicates/ignore#new', as: 'new_ignore'
          post 'ignore' => 'person_duplicates/ignore#create', as: 'ignore'
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

        resources :terminations, module: :roles, only: %w(new create)
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
      get 'events/invitation_lists/new' => 'event/invitation_lists#new'

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

          resource :invitation_lists, only: :create
          resources :invitations, only: [:index, :new, :create, :edit, :destroy] do
            member do
              post 'decline' => 'invitations/decline#create'
            end
          end

          resources :applications, only: [] do
            member do
              put    :approve
              delete :reject
            end
          end

          resources :attachments, only: [:create, :update, :destroy]

          resource :participation_lists, only: :create
          resources :participations do
            collection do
              get 'contact_data', controller: 'participation_contact_datas', action: 'edit'
              post 'contact_data', controller: 'participation_contact_datas', action: 'update'
            end
            resource :mail_dispatch, only: [:create], module: :participations
            member do
              get 'print'
            end
          end

          resources :roles, except: [:index, :show]
          get 'roles' => 'roles#new' # route required for language switch
          get 'roles/:id' => 'roles#edit' # route required for language switch

          get 'qualifications' => 'qualifications#index'
          put 'qualifications' => 'qualifications#update'

          post 'tags' => 'tags#create'
          delete 'tags' => 'tags#destroy'
          get 'tags/query' => 'tags#query'
        end

      end

      resources :mailing_lists do
        resource :subscriber_list, only: [:create], module: :subscriber
        resources :messages

        resources :subscriptions, only: [:index, :destroy] do
          collection do
            resources :person, only: [:new, :create], controller: 'subscriber/person'
            get 'person' => 'subscriber/person#new' # route required for language switch

            resources :exclude_person, only: [:new, :create],
                                       controller: 'subscriber/exclude_person'
            get 'exclude_person' => 'subscriber/exclude_person#new' # route required for language switch

            resources :group, only: [:new, :create, :edit, :update],
                              controller: 'subscriber/group' do
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

            resource :filter, only: [:edit, :update], controller: 'subscriber/filter'

          end

        end

        resources :mailchimp_synchronizations, only: [:create]
        resources :recipient_counts, controller: 'mailing_lists/recipient_counts', only: [:index]
      end

      resources :calendars do
        get 'feed' => 'calendars/feeds#index'
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

    resources :hours do
      collection do
        get :approve
        get :hours_summary
        get :new_submission
        post :submit_additional_event, action: :submit_additional_event
        post :bulk_submit_for_event
      end
    end

    resources :reportings do
      collection do
        get :hours_approval
        get :hours_summary
        post :update_hours_approval
        get :download_hours, defaults: { format: :csv }
      end
    end

    resources :notifications do
      collection do
        get :event
        post :notify
      end
    end

    get 'list_courses' => 'events/courses#index', as: :list_courses
    get 'list_events' => 'event/lists#events', as: :list_events

    get 'full' => 'full_text#index'

    resources :event_kinds, module: 'event', controller: 'kinds'
    resources :event_kind_categories, module: 'event', controller: 'kind_categories'

    get 'hitobito_log_entries(/:category)', to: 'hitobito_log_entries#index',
                                            as: :hitobito_log_entries

    scope 'mailing_lists', module: :mailing_lists do
      scope 'imap_mails' do
        get ':mailbox' => 'imap_mails#index', as: :imap_mails
        delete ':mailbox' => 'imap_mails#destroy', as: :imap_mails_destroy
        patch ':mailbox/move' => 'imap_mails_move#create', as: :imap_mails_move
      end
    end

    resources :qualification_kinds
    resources :tags, except: :show do
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

    resources :self_registration_reasons

    resources :custom_contents, only: [:index, :edit, :update]
    get 'custom_contents/:id' => 'custom_contents#edit'

    resource :event_feed, only: [:show, :update]
    resources :help_texts, except: [:show]

    devise_for :service_tokens, only: [:sessions]
    devise_for :people, skip: [:registrations], path: 'users', controllers: {
      passwords: 'devise/hitobito/passwords',
      registrations: 'devise/hitobito/registrations',
      sessions: 'devise/hitobito/sessions'
    }
    devise_for :oauth_tokens, skip: :all, class_name: 'Oauth::AccessToken'
    as :person do
      get 'users/edit' => 'devise/hitobito/registrations#edit', :as => 'edit_person_registration'
      put 'users' => 'devise/hitobito/registrations#update', :as => 'person_registration'
      get 'users' => 'devise/hitobito/registrations#edit' # route required for language switch

      get 'users/second_factor' => 'second_factor_authentication#new', as: 'new_users_second_factor'
      post 'users/second_factor' => 'second_factor_authentication#create', as: 'users_second_factor'

      post 'users/token' => 'devise/tokens#create'
      delete 'users/token' => 'devise/tokens#destroy'
    end

    post 'person_add_requests/:id' => 'person/add_requests#approve', as: :person_add_request
    delete 'person_add_requests/:id' => 'person/add_requests#reject'

    get 'changelog' => 'changelog#index'

    get 'downloads/:id' => 'async_downloads#show'
    get 'downloads/:id/exists' => 'async_downloads#exists?'

    get 'synchronizations/:id' => 'async_synchronizations#show'

    resources :assignments, only: [:new, :create]
    resources :table_displays, only: [:create]
    resources :messages, only: [:show] do
      resource :preview, only: [:show], module: :messages
      resource :dispatch, only: [:create, :show], module: :messages
    end
  end # scope locale

  get '/api', to: 'json_api/documentation#index'
  mount Rswag::Ui::Engine => '/api-docs'
  mount Rswag::Api::Engine => '/api-docs'

  get 'api/schema', to: 'json_api/schema#show'
  get 'api/openapi', to: 'json_api/openapi#show'

  scope path: ApplicationResource.endpoint_namespace, module: :json_api,
        constraints: { format: 'jsonapi' }, defaults: { format: 'jsonapi' } do
    resources :people, only: [:index, :show, :update]
    resources :groups, only: [:index, :show]
    resources :events, only: [:index, :show]
    resources :event_kinds, module: :event, controller: :kinds, only: [:index, :show]
    resources :event_kind_categories, module: :event, controller: :kind_categories, only: [:index, :show]
    resources :invoices, only: [:index, :show, :update]
    resources :roles, except: [:edit, :new]
  end

  # The priority is based upon order of creation:
  # first created -> highest priority.

  # See how all your routes lay out with "rake routes"
end
