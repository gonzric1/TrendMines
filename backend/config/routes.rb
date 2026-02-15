Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Devise authentication routes (outside namespaces to keep :user scope)
  devise_for :users,
             path: "api/v1/auth",
             controllers: {
               sessions: "api/v1/auth/sessions",
               registrations: "api/v1/auth/registrations"
             }

  # API Routes
  namespace :api do
    namespace :v1 do
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

      # Settings
      get 'settings', to: 'settings#index'
      patch 'settings', to: 'settings#update'
      scope :settings do
        get 'api_keys', to: 'settings#api_keys', as: :settings_api_keys
        patch 'api_keys', to: 'settings#update_api_keys', as: :settings_update_api_keys
        post 'test_connection', to: 'settings#test_connection', as: :settings_test_connection
      end

      # Products
      resources :products do
        member do
          get :listings
          get :metrics
          post :list
          get :decay_analysis
          patch :transition
        end
      end

      # Analytics
      scope :analytics do
        get 'revenue', to: 'analytics#revenue', as: :analytics_revenue
        get 'funnel', to: 'analytics#funnel', as: :analytics_funnel
        get 'sources', to: 'analytics#sources', as: :analytics_sources
        get 'costs', to: 'analytics#costs', as: :analytics_costs
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
