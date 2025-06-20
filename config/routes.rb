Rails.application.routes.draw do
  devise_for :users
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Admin routes
  get 'admin', to: 'admin#index'
  patch 'admin/zines/:id/approve', to: 'admin#approve', as: 'admin_approve_zine'
  delete 'admin/zines/:id/reject', to: 'admin#reject', as: 'admin_reject_zine'
  delete 'admin/zines/:id', to: 'admin#destroy', as: 'admin_destroy_zine'

  # User dashboard
  get 'dashboard', to: 'users#dashboard'

  # Zines routes
  resources :zines, only: [:index, :show, :new, :create, :edit, :update, :destroy]

  # Defines the root path route ("/")
  root "zines#index"
end
