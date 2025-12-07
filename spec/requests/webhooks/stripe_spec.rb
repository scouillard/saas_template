require "rails_helper"

RSpec.describe "Webhooks::Stripe", type: :request do
  let(:webhook_secret) { "whsec_test_secret" }
  let(:payload) { { type: "invoice.payment_failed", data: { object: {} } }.to_json }

  before do
    allow(Rails.application.credentials).to receive(:dig).with(:stripe, :webhook_secret).and_return(webhook_secret)
  end

  describe "POST /webhooks/stripe" do
    context "with valid signature" do
      let(:timestamp) { Time.now.to_i }
      let(:signature) do
        signed_payload = "#{timestamp}.#{payload}"
        "t=#{timestamp},v1=#{OpenSSL::HMAC.hexdigest('SHA256', webhook_secret, signed_payload)}"
      end

      it "returns ok status" do
        allow(Stripe::WebhookProcessor).to receive(:call).and_return(true)

        post webhooks_stripe_path,
          params: payload,
          headers: { "HTTP_STRIPE_SIGNATURE" => signature, "CONTENT_TYPE" => "application/json" }

        expect(response).to have_http_status(:ok)
      end

      it "calls the webhook processor" do
        allow(Stripe::WebhookProcessor).to receive(:call).and_return(true)

        post webhooks_stripe_path,
          params: payload,
          headers: { "HTTP_STRIPE_SIGNATURE" => signature, "CONTENT_TYPE" => "application/json" }

        expect(Stripe::WebhookProcessor).to have_received(:call)
      end
    end

    context "with invalid signature" do
      it "returns bad request status" do
        post webhooks_stripe_path,
          params: payload,
          headers: { "HTTP_STRIPE_SIGNATURE" => "invalid", "CONTENT_TYPE" => "application/json" }

        expect(response).to have_http_status(:bad_request)
      end
    end

    context "with missing signature" do
      it "returns bad request status" do
        post webhooks_stripe_path,
          params: payload,
          headers: { "CONTENT_TYPE" => "application/json" }

        expect(response).to have_http_status(:bad_request)
      end
    end
  end
end
