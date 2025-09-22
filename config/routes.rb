require 'sidekiq/web'
Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check
  # sidekiq
  mount Sidekiq::Web => '/sidekiq'
  # signup routes
  get "sign_up",to: "users#new"
  post "sign_up", to: "users#create"
  resources :users, only: [ :show, :edit, :update] do
    collection do
      get :check_username
    end
  end
  # login routes
  get "login", to: "sessions#new"
  post "login", to: "sessions#create"
  delete "logout", to: "sessions#destroy"

  # password reset routes
  resources :password_resets, only: [:new, :create, :edit, :update,]

  # article resources
  resources :articles do
    member do
      patch :restore
      patch :hide
      post :toggle_clap
    end
    collection do
      post :upload_image
      post :fetch_image_url
      post :upload_file
    end
    resources :comments, only: [ :create, :edit, :update, :destroy ] do
      resources :reports, only: [:new, :create], shallow: true
    end
    resources :reports, only: [:new, :create], shallow: true
  end

  # topic resources
  resources :topics, only: [ :show ]

  # Admin resources
  namespace :admin do
    root "dashboard#index"
    resource :moderation, only: [:show]
    resources :users, only: [ :index, :destroy] do
      member do
        patch :update_role
        patch :restore
      end
    end
    resources :articles, only: [ :destroy ] do
      member do
        patch :resolve_reports
        patch :dismiss_reports
      end
    end
    # Comments resources
    resources :comments, only: [ :destroy] do
      member do
        patch :resolve_reports
        patch :dismiss_reports
      end
      resources :reports, only: [:new, :create], shallow: true
    end
  end
  # dashboard
  root "articles#index"
  match "*path", to: "application#not_found", via: :all, constraints: ->(req) { !req.path.start_with?('/rails/active_storage') }
end
