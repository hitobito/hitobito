Rails.application.routes.draw do

  resources :censuses, only: [:new, :create]

  resources :event_camp_kinds, module: 'event', controller: 'camp/kinds'

  resources :groups do
    member do
      scope module: 'census_evaluation' do
        get 'census/federation' => 'federation#index'
        get 'census/state' => 'state#index'
        get 'census/flock' => 'flock#index'
        post 'census/state/remind' => 'state#remind'
      end

      get 'population' => 'population#index'
    end

    resources :events, only: [] do # do not redefine events actions, only add new ones
      collection do
        get 'camp' => 'events#index', type: 'Event::Camp'
      end
    end

    resources :event_course_conditions, module: 'event', controller: 'course/conditions'
    resource :member_counts, only: [:create, :edit, :update]
  end

end
