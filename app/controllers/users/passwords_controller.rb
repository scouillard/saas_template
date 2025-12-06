# frozen_string_literal: true

class Users::PasswordsController < Devise::PasswordsController
  rate_limit to: RateLimiting::PASSWORD_RESET_LIMIT,
             within: RateLimiting::ONE_HOUR,
             only: :create
end
