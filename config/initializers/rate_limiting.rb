# frozen_string_literal: true

module RateLimiting
  # Public endpoints (aggressive limits)
  REGISTRATION_LIMIT = 5        # per hour
  PASSWORD_RESET_LIMIT = 3      # per hour
  CONTACT_FORM_LIMIT = 3        # per 10 minutes
  NEWSLETTER_LIMIT = 2          # per hour
  INVITATION_ACCEPT_LIMIT = 10  # per hour
  INVITATION_CREATE_LIMIT = 20  # per hour

  # Authenticated endpoints (moderate limits)
  PROFILE_UPDATE_LIMIT = 20     # per hour
  PROFILE_DELETE_LIMIT = 3      # per hour
  CHECKOUT_LIMIT = 10           # per 5 minutes
  NOTIFICATION_LIMIT = 100      # per minute

  # Periods
  ONE_MINUTE = 1.minute
  FIVE_MINUTES = 5.minutes
  TEN_MINUTES = 10.minutes
  ONE_HOUR = 1.hour
end
