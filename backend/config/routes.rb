Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # API Routes
  namespace :api do
    namespace :v1 do
      # Authentication routes
      scope :auth do
        devise_for :users,
                   path: "",
                   controllers: {
                     sessions: "api/v1/auth/sessions",
                     registrations: "api/v1/auth/registrations"
                   }
      end
      # Trend Signals
      resources :trend_signals do
        member do
          get :history
        end
      end

      # Niches
      resources :niches do
        member do
          get :tokens
          get :designs
          get :scorecard
        end
      end

      # Cultural Tokens
      resources :cultural_tokens do
        member do
          get :sources
          post :generate
        end
      end

      # Designs
      resources :designs do
        member do
          post :regenerate
        end
      end

      # Products
      resources :products do
        member do
          get :listings
          get :metrics
          post :list
        end
      end

      # Listings
      resources :listings do
        member do
          get :metrics
          post 'metrics', action: :create_metric
        end
        collection do
          get :alerts
          get :leaderboard
        end
      end
    end
  end
end
