module Webhooks
  class StripeController < ApplicationController
    skip_before_action :verify_authenticity_token

    def create
      payload = request.body.read
      sig_header = request.env["HTTP_STRIPE_SIGNATURE"]

      event = construct_event(payload, sig_header)
      return head :bad_request unless event

      Stripe::WebhookProcessor.call(event)

      head :ok
    end

    private

    def construct_event(payload, sig_header)
      ::Stripe::Webhook.construct_event(
        payload, sig_header, webhook_secret
      )
    rescue JSON::ParserError => e
      Rails.logger.error("Stripe webhook JSON parse error: #{e.message}")
      nil
    rescue ::Stripe::SignatureVerificationError => e
      Rails.logger.error("Stripe webhook signature error: #{e.message}")
      nil
    end

    def webhook_secret
      Rails.application.credentials.dig(:stripe, :webhook_secret) ||
        ENV.fetch("STRIPE_WEBHOOK_SECRET", nil)
    end
  end
end
