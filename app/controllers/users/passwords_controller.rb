# frozen_string_literal: true

class Users::PasswordsController < Devise::PasswordsController
  # Strict limit for public endpoint (3 per hour)
  rate_limit to: 3, within: 1.hour, only: :create
end
