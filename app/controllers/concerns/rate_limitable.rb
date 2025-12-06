# frozen_string_literal: true

module RateLimitable
  extend ActiveSupport::Concern

  private

  def rate_limit_key
    current_user&.id&.to_s || request.remote_ip
  end
end
