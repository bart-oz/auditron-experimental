Rails.application.routes.draw do
  # Health check endpoint
  get "up" => "rails/health#show", as: :rails_health_check

  # API v1 routes
  namespace :api do
    namespace :v1 do
      post "reconcile", to: "reconciliations#create"
      resources :reconciliations, only: [:index, :show] do
        member do
          get :report
        end
      end
    end
  end
end
