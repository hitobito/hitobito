Rails.application.routes.draw do
  
  resources :groups do
    member do
      scope module: 'census_evaluation' do
        get 'census/federation' => 'federation#index'
        get 'census/state' => 'state#index'
        get 'census/flock' => 'flock#index'
      end
    end
  end
  
end
