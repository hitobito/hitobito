Rails.application.routes.draw do
  
  resources :groups do
    member do
      scope module: 'census_evaluation' do
        get 'census/federation/total' => 'federation#total'
        get 'census/federation/detail' => 'federation#detail'
        get 'census/state/total' => 'state#total'
        get 'census/state/detail' => 'state#detail'
        get 'census/flock/total' => 'flock#total'
        get 'census/flock/detail' => 'flock#detail'
      end
    end
  end
  
end
