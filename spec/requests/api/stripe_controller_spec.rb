require "rails_helper"

RSpec.describe "Api::StripeController", type: :request do
  let(:webhook_secret) { "whsec_test_secret" }

  before do
    allow(Rails.application.credentials).to receive(:dig).with(:stripe, :webhook_secret).and_return(webhook_secret)
  end

  def generate_signature(payload)
    timestamp = Time.now.to_i
    signed_payload = "#{timestamp}.#{payload}"
    signature = OpenSSL::HMAC.hexdigest("SHA256", webhook_secret, signed_payload)
    "t=#{timestamp},v1=#{signature}"
  end

  describe "POST /api/stripe/webhook" do
    context "with invalid signature" do
      it "returns bad request" do
        post "/api/stripe/webhook",
             params: { type: "checkout.session.completed" }.to_json,
             headers: { "Stripe-Signature" => "invalid", "Content-Type" => "application/json" }

        expect(response).to have_http_status(:bad_request)
      end
    end

    context "when checkout.session.completed with existing account" do
      let(:account) { create(:account) }
      let(:payload) do
        {
          type: "checkout.session.completed",
          data: {
            object: {
              client_reference_id: account.id.to_s,
              customer: "cus_test123",
              subscription: "sub_test456"
            }
          }
        }.to_json
      end

      it "updates the account with stripe info and sets plan to pro" do # rubocop:disable RSpec/MultipleExpectations
        post "/api/stripe/webhook",
             params: payload,
             headers: { "Stripe-Signature" => generate_signature(payload), "Content-Type" => "application/json" }

        expect(response).to have_http_status(:ok)
        account.reload
        expect(account.stripe_customer_id).to eq("cus_test123")
        expect(account.stripe_subscription_id).to eq("sub_test456")
        expect(account.plan).to eq("pro")
        expect(account.subscription_status).to eq("active")
        expect(account.subscription_started_at).to be_present
      end
    end

    context "when checkout.session.completed with missing account" do
      let(:payload) do
        {
          type: "checkout.session.completed",
          data: {
            object: {
              client_reference_id: "999999",
              customer: "cus_test123",
              subscription: "sub_test456"
            }
          }
        }.to_json
      end

      it "returns ok without error" do
        post "/api/stripe/webhook",
             params: payload,
             headers: { "Stripe-Signature" => generate_signature(payload), "Content-Type" => "application/json" }

        expect(response).to have_http_status(:ok)
      end
    end

    context "when customer.subscription.deleted with existing account" do
      let(:account) { create(:account, :with_stripe, plan: :pro) }
      let(:payload) do
        {
          type: "customer.subscription.deleted",
          data: {
            object: {
              id: account.stripe_subscription_id
            }
          }
        }.to_json
      end

      it "resets the account to free plan" do
        post "/api/stripe/webhook",
             params: payload,
             headers: { "Stripe-Signature" => generate_signature(payload), "Content-Type" => "application/json" }

        expect(response).to have_http_status(:ok)
        account.reload
        expect(account.plan).to eq("free")
        expect(account.stripe_subscription_id).to be_nil
        expect(account.subscription_status).to be_nil
        expect(account.subscription_ends_at).to be_present
      end
    end

    context "when customer.subscription.deleted with missing account" do
      let(:payload) do
        {
          type: "customer.subscription.deleted",
          data: {
            object: {
              id: "sub_nonexistent"
            }
          }
        }.to_json
      end

      it "returns ok without error" do
        post "/api/stripe/webhook",
             params: payload,
             headers: { "Stripe-Signature" => generate_signature(payload), "Content-Type" => "application/json" }

        expect(response).to have_http_status(:ok)
      end
    end

    context "when customer.subscription.updated with existing account" do
      let(:account) { create(:account, :with_stripe, plan: :pro) }
      let(:period_end) { 30.days.from_now.to_i }
      let(:payload) do
        {
          type: "customer.subscription.updated",
          data: {
            object: {
              id: account.stripe_subscription_id,
              status: "past_due",
              current_period_end: period_end
            }
          }
        }.to_json
      end

      it "updates subscription status and period end" do
        post "/api/stripe/webhook",
             params: payload,
             headers: { "Stripe-Signature" => generate_signature(payload), "Content-Type" => "application/json" }

        expect(response).to have_http_status(:ok)
        account.reload
        expect(account.subscription_status).to eq("past_due")
        expect(account.current_period_ends_at).to be_within(1.second).of(Time.at(period_end))
      end
    end

    context "when customer.subscription.updated with missing account" do
      let(:payload) do
        {
          type: "customer.subscription.updated",
          data: {
            object: {
              id: "sub_nonexistent",
              status: "active",
              current_period_end: 30.days.from_now.to_i
            }
          }
        }.to_json
      end

      it "returns ok without error" do
        post "/api/stripe/webhook",
             params: payload,
             headers: { "Stripe-Signature" => generate_signature(payload), "Content-Type" => "application/json" }

        expect(response).to have_http_status(:ok)
      end
    end

    context "when invoice.payment_failed with existing account" do
      let(:account) { create(:account, :with_stripe, plan: :pro, subscription_status: "active") }
      let(:payload) do
        {
          type: "invoice.payment_failed",
          data: {
            object: {
              customer: account.stripe_customer_id
            }
          }
        }.to_json
      end

      it "sets subscription status to past_due" do
        post "/api/stripe/webhook",
             params: payload,
             headers: { "Stripe-Signature" => generate_signature(payload), "Content-Type" => "application/json" }

        expect(response).to have_http_status(:ok)
        account.reload
        expect(account.subscription_status).to eq("past_due")
      end
    end

    context "when invoice.payment_failed with missing account" do
      let(:payload) do
        {
          type: "invoice.payment_failed",
          data: {
            object: {
              customer: "cus_nonexistent"
            }
          }
        }.to_json
      end

      it "returns ok without error" do
        post "/api/stripe/webhook",
             params: payload,
             headers: { "Stripe-Signature" => generate_signature(payload), "Content-Type" => "application/json" }

        expect(response).to have_http_status(:ok)
      end
    end
  end
end
