module Webhooks
  class StripeController < ApplicationController
    skip_before_action :verify_authenticity_token

    def create
      payload = request.body.read
      sig_header = request.env["HTTP_STRIPE_SIGNATURE"]

      event = construct_event(payload, sig_header)
      return head :bad_request unless event

      Stripe::WebhookHandler.new(event).call

      head :ok
    end

    private

    def construct_event(payload, sig_header)
      ::Stripe::Webhook.construct_event(payload, sig_header, webhook_secret)
    rescue ::Stripe::SignatureVerificationError => e
      Rails.logger.error("[Stripe] Signature verification failed: #{e.message}")
      nil
    rescue JSON::ParserError => e
      Rails.logger.error("[Stripe] Invalid payload: #{e.message}")
      nil
    end

    def webhook_secret
      ENV.fetch("STRIPE_WEBHOOK_SECRET")
    end
  end
end
