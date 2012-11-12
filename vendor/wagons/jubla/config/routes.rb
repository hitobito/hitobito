Rails.application.routes.draw do
  resources :event_camp_kinds, module: 'event', controller: 'camp/kinds'
end
