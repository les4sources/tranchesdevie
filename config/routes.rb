Rails.application.routes.draw do
  # Admin namespace
  namespace :admin do
    root "dashboard#index"
    
    resources :bake_days do
      member do
        post :lock
        post :unlock
        post :complete
      end
      
      resources :production_caps do
        collection do
          post :bulk_update
          post :copy_from
        end
      end
    end
  end

  # Public catalog (no authentication required)
  resources :products, only: [:index, :show]
  
  # Root path
  root "products#index"

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
end
