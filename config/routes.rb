Jubla::Application.routes.draw do

  root :to => 'dashboard#index'

  resources :groups do
    resources :people do
      member do
        get :history
        post :send_password_instructions
      end
      resources :qualifications, only: [:new, :create, :destroy]
    end

    resources :roles, except: [:index, :show]

    resources :people_filters, only: [:new, :create, :destroy]

    resources :events do
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
      end

    end
    
    resources :mailing_lists do
      resources :subscriptions
    end

    resource :csv_imports, only: [:new, :create] do
      post :define_mapping, on: :member
    end

    member do
      get 'merge' => 'group/merge#select'
      post 'merge' => 'group/merge#perform'

      get 'move' => 'group/move#select'
      post 'move' => 'group/move#perform'
    end
  end

  get 'list_courses' => 'event/lists#courses', as: :list_courses
  get 'list_events' => 'event/lists#events', as: :list_events

  get 'full' => 'full_text#index'
  get 'query' => 'full_text#query'

  resources :people, only: :show do
    collection do
      get :query
    end
  end

  resources :event_kinds, module: 'event', controller: 'kinds'

  resources :qualification_kinds

  resources :label_formats

  resources :custom_contents, only: [:index, :edit, :update]

  devise_for :people, skip: [:registrations], path: "users"
  as :person do
    get 'users/edit' => 'devise/registrations#edit', :as => 'edit_person_registration'
    put 'users' => 'devise/registrations#update', :as => 'person_registration'
  end

  get 'static/:action', controller: 'static'


  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Sample resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  # root :to => 'welcome#index'

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id))(.:format)'
end
