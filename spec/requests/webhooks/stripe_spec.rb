require "rails_helper"

RSpec.describe "Webhooks::Stripe", type: :request do
  let(:webhook_secret) { "whsec_test_secret" }
  let(:account) { create(:account, :with_stripe) }

  before do
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with("STRIPE_WEBHOOK_SECRET").and_return(webhook_secret)
  end

  describe "POST /webhooks/stripe" do
    context "with valid signature" do
      it "returns 200 OK for checkout.session.completed" do
        event = build_stripe_event("checkout.session.completed", {
          customer: account.stripe_customer_id,
          subscription: "sub_new123",
          client_reference_id: account.id.to_s
        })

        post webhooks_stripe_path, params: event.to_json, headers: stripe_headers(event.to_json)

        expect(response).to have_http_status(:ok)
      end

      it "returns 200 OK for customer.subscription.created" do
        event = build_stripe_event("customer.subscription.created", {
          id: account.stripe_subscription_id,
          customer: account.stripe_customer_id,
          status: "active",
          current_period_start: Time.current.to_i,
          current_period_end: 1.month.from_now.to_i,
          items: { data: [ { price: { id: "price_pro_monthly" } } ] }
        })

        post webhooks_stripe_path, params: event.to_json, headers: stripe_headers(event.to_json)

        expect(response).to have_http_status(:ok)
        expect(account.reload.subscription_status).to eq("active")
      end

      it "returns 200 OK for customer.subscription.updated" do
        event = build_stripe_event("customer.subscription.updated", {
          id: account.stripe_subscription_id,
          customer: account.stripe_customer_id,
          status: "active",
          current_period_start: Time.current.to_i,
          current_period_end: 1.month.from_now.to_i,
          items: { data: [ { price: { id: "price_pro_monthly" } } ] }
        })

        post webhooks_stripe_path, params: event.to_json, headers: stripe_headers(event.to_json)

        expect(response).to have_http_status(:ok)
      end

      it "returns 200 OK for customer.subscription.deleted" do
        event = build_stripe_event("customer.subscription.deleted", {
          id: account.stripe_subscription_id,
          customer: account.stripe_customer_id,
          status: "canceled",
          current_period_end: 1.month.from_now.to_i
        })

        post webhooks_stripe_path, params: event.to_json, headers: stripe_headers(event.to_json)

        expect(response).to have_http_status(:ok)
        expect(account.reload.subscription_status).to eq("cancelled")
      end

      it "returns 200 OK for invoice.paid" do
        event = build_stripe_event("invoice.paid", {
          customer: account.stripe_customer_id,
          subscription: account.stripe_subscription_id
        })

        post webhooks_stripe_path, params: event.to_json, headers: stripe_headers(event.to_json)

        expect(response).to have_http_status(:ok)
      end

      it "returns 200 OK for invoice.payment_failed" do
        account.update!(subscription_status: "active")
        event = build_stripe_event("invoice.payment_failed", {
          customer: account.stripe_customer_id,
          subscription: account.stripe_subscription_id
        })

        post webhooks_stripe_path, params: event.to_json, headers: stripe_headers(event.to_json)

        expect(response).to have_http_status(:ok)
        expect(account.reload.subscription_status).to eq("past_due")
      end

      it "returns 200 OK for unknown event types" do
        event = build_stripe_event("unknown.event.type", {})

        post webhooks_stripe_path, params: event.to_json, headers: stripe_headers(event.to_json)

        expect(response).to have_http_status(:ok)
      end
    end

    context "with invalid signature" do
      it "returns 400 Bad Request" do
        event = build_stripe_event("checkout.session.completed", {})

        post webhooks_stripe_path, params: event.to_json, headers: { "HTTP_STRIPE_SIGNATURE" => "invalid" }

        expect(response).to have_http_status(:bad_request)
      end
    end

    context "with invalid JSON payload" do
      it "returns 400 Bad Request" do
        post webhooks_stripe_path, params: "invalid json", headers: stripe_headers("invalid json")

        expect(response).to have_http_status(:bad_request)
      end
    end
  end

  private

  def build_stripe_event(type, data)
    {
      id: "evt_#{SecureRandom.hex(12)}",
      type: type,
      data: { object: data }
    }
  end

  def stripe_headers(payload)
    timestamp = Time.current.to_i
    signature = compute_signature(timestamp, payload)

    {
      "HTTP_STRIPE_SIGNATURE" => "t=#{timestamp},v1=#{signature}",
      "CONTENT_TYPE" => "application/json"
    }
  end

  def compute_signature(timestamp, payload)
    signed_payload = "#{timestamp}.#{payload}"
    OpenSSL::HMAC.hexdigest("SHA256", webhook_secret, signed_payload)
  end
end
