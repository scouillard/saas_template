Rails.application.routes.draw do
  devise_for :users, controllers: {
    omniauth_callbacks: "users/omniauth_callbacks",
    registrations: "users/registrations"
  }

  # Stripe webhook
  post "/webhooks/stripe", to: "webhooks/stripe#create"

  # Invitation acceptance flow
  get "invitations/:token", to: "account_invitations#show", as: :accept_invitation
  post "invitations/:token/accept", to: "account_invitations#accept", as: :confirm_invitation

  post "notifications/mark_all_seen", to: "notifications#mark_all_seen", as: :mark_all_seen_notifications
  post "notifications/:id/read", to: "notifications#mark_as_read", as: :read_notification

  # User settings
  resource :profile, only: [ :show, :update, :destroy ] do
    get "password/edit", action: :edit_password, as: :edit_password
    patch "password", action: :update_password, as: :update_password
    get "delete", action: :confirm_destroy, as: :confirm_destroy
  end

  # Account settings
  resource :team, only: [ :show, :update ]
  resources :invitations, only: [ :create, :destroy ], controller: "account_invitations"
  resource :settings, only: [ :show, :update ]
  resource :plan, only: [ :show ]
  get "pricing", to: "pricing#index"

  # Stripe Checkout
  post "checkout", to: "stripe_checkout#create"
  get "checkout/success", to: "checkouts#success", as: :checkout_success

  # Stripe Webhooks
  post "webhooks/stripe", to: "webhooks/stripe#create"

  # Billing (redirects to Stripe Customer Portal)
  get "billing", to: "billing#show"

  # Static pages
  get "privacy", to: "home#privacy"
  get "terms", to: "home#terms"

  # Contact form
  get "contact", to: "contact#new"
  post "contact", to: "contact#create"

  # Newsletter subscribe / waitlist
  get "subscribe", to: "subscribers#new"
  post "subscribe", to: "subscribers#create"

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  root "home#index"
end
