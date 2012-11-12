Rails.application.routes.draw do

  resources :event_camp_kinds, module: 'event', controller: 'camp/kinds'
  
  resources :groups do
    member do
      scope module: 'census_evaluation' do
        get 'census/federation' => 'federation#index'
        get 'census/state' => 'state#index'
        get 'census/flock' => 'flock#index'
      end
      
      get 'population' => 'population#index'
      
    end
    
    resource :member_counts, only: [:create, :edit, :update]
  end
  
end
