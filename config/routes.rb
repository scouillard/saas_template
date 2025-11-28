Rails.application.routes.draw do
  devise_for :users, controllers: {
    omniauth_callbacks: "users/omniauth_callbacks",
    registrations: "users/registrations"
  }

  # Invitation acceptance flow
  get "invitations/:token", to: "invitation_acceptances#show", as: :accept_invitation
  post "invitations/:token/accept", to: "invitation_acceptances#accept", as: :confirm_invitation

  post "notifications/mark_all_seen", to: "notifications#mark_all_seen", as: :mark_all_seen_notifications
  post "notifications/:id/read", to: "notifications#mark_as_read", as: :read_notification

  # User settings
  resource :profile, only: [ :show, :update ] do
    get "password/edit", action: :edit_password, as: :edit_password
    patch "password", action: :update_password, as: :update_password
  end

  # Account settings
  resource :team, only: [ :show, :update ]
  resources :invitations, only: [ :create, :destroy ]
  resource :settings, only: [ :show, :update ]
  resource :plan, only: [ :show ]
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  root "home#index"
end
