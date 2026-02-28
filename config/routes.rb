Rails.application.routes.draw do
  # Auth
  get  "sign_in",  to: "sessions#new"
  post "sign_in",  to: "sessions#create"
  get  "sign_up",  to: "registrations#new"
  post "sign_up",  to: "registrations#create"

  resources :sessions, only: %i[index show destroy]
  resource  :password, only: %i[edit update]

  namespace :identity do
    resource :email,              only: %i[edit update]
    resource :email_verification, only: %i[show create]
    resource :password_reset,     only: %i[new edit create update]
  end

  namespace :two_factor_authentication do
    namespace :challenge do
      resource :totp,           only: %i[new create]
      resource :recovery_codes, only: %i[new create]
    end
    namespace :profile do
      resource  :totp,           only: %i[new create update]
      resources :recovery_codes, only: %i[index create]
    end
  end

  # OmniAuth
  get  "/auth/failure",            to: "sessions/omniauth#failure"
  get  "/auth/:provider/callback", to: "sessions/omniauth#create"
  post "/auth/:provider/callback", to: "sessions/omniauth#create"

  # Invitations (unauthenticated — token-based password setup)
  resources :invitations, only: %i[show update], param: :token

  # Chat
  resources :conversations, only: %i[index show] do
    collection do
      get  :mine
      post :mark_client_read
    end
    member do
      post :mark_read
    end
    resources :messages, only: %i[create]
  end

  # Admin resources
  resources :users, only: %i[index show new create edit update destroy] do
    resource :approval, only: %i[update], controller: "approvals"
  end
  resources :roles
  resources :genres
  resources :subgenres
  resources :client_types
  resources :site_settings, except: %i[new create destroy] do
    member { patch :reset }
    collection do
      patch :update_branding
      patch :update_company
      patch :update_display
    end
  end

  # Scaffolded content resources
  resources :books
  resources :authors do
    collection { get :search, defaults: { format: :json } }
  end
  resources :companies do
    collection { get :search, defaults: { format: :json } }
  end
  resources :contacts do
    collection { get :search, defaults: { format: :json } }
  end
  resources :company_types
  resources :territories

  # Dashboard & misc
  get  "dashboard",        to: "home#dashboard", as: :dashboard
  get  "pending_approval", to: "home#pending_approval", as: :pending_approval

  root "home#index"

  get "up" => "rails/health#show", as: :rails_health_check
end
