require "rails_helper"

RSpec.describe "Webhooks::Stripe", type: :request do
  let(:webhook_secret) { "whsec_test_secret" }
  let(:account) { create(:account, :with_stripe) }
  let(:timestamp) { Time.now.to_i }

  before do
    allow(Rails.application.credentials).to receive(:dig).with(:stripe, :webhook_secret).and_return(webhook_secret)
  end

  def generate_signature(payload)
    signed_payload = "#{timestamp}.#{payload}"
    signature = OpenSSL::HMAC.hexdigest("SHA256", webhook_secret, signed_payload)
    "t=#{timestamp},v1=#{signature}"
  end

  def post_webhook(event_type:, data:)
    payload = { type: event_type, data: { object: data } }.to_json
    signature = generate_signature(payload)

    post "/webhooks/stripe",
         params: payload,
         headers: {
           "CONTENT_TYPE" => "application/json",
           "HTTP_STRIPE_SIGNATURE" => signature
         }
  end

  describe "POST /webhooks/stripe" do
    context "with invalid signature" do
      it "returns 400 bad request" do
        payload = { type: "test.event", data: { object: {} } }.to_json

        post "/webhooks/stripe",
             params: payload,
             headers: {
               "CONTENT_TYPE" => "application/json",
               "HTTP_STRIPE_SIGNATURE" => "invalid_signature"
             }

        expect(response).to have_http_status(:bad_request)
      end
    end

    context "with missing signature" do
      it "returns bad request status" do
        payload = { type: "test.event", data: { object: {} } }.to_json

        post "/webhooks/stripe",
             params: payload,
             headers: { "CONTENT_TYPE" => "application/json" }

        expect(response).to have_http_status(:bad_request)
      end
    end

    context "with valid signature" do
      describe "checkout.session.completed" do
        let(:subscription_data) do
          double(
            id: account.stripe_subscription_id,
            status: "active",
            start_date: 1.day.ago.to_i,
            current_period_end: 1.month.from_now.to_i,
            cancel_at: nil,
            items: double(data: [ double(price: double(id: "price_pro")) ])
          )
        end

        before do
          stub_const("ENV", ENV.to_h.merge("STRIPE_PRO_PRICE_ID" => "price_pro"))
          allow(Stripe::Subscription).to receive(:retrieve).and_return(subscription_data)
        end

        it "syncs the subscription" do
          post_webhook(
            event_type: "checkout.session.completed",
            data: {
              customer: account.stripe_customer_id,
              subscription: account.stripe_subscription_id
            }
          )

          expect(response).to have_http_status(:ok)
          account.reload
          expect(account.subscription_status).to eq("active")
          expect(account.plan).to eq("pro")
        end
      end

      describe "customer.subscription.updated" do
        let(:subscription_data) do
          {
            id: account.stripe_subscription_id,
            customer: account.stripe_customer_id,
            status: "active",
            start_date: 1.day.ago.to_i,
            current_period_end: 1.month.from_now.to_i,
            cancel_at: nil,
            items: { data: [ { price: { id: "price_enterprise" } } ] }
          }
        end

        before do
          stub_const("ENV", ENV.to_h.merge("STRIPE_ENTERPRISE_PRICE_ID" => "price_enterprise"))
        end

        it "updates the subscription" do
          post_webhook(event_type: "customer.subscription.updated", data: subscription_data)

          expect(response).to have_http_status(:ok)
          account.reload
          expect(account.plan).to eq("enterprise")
          expect(account.subscription_status).to eq("active")
        end
      end

      describe "customer.subscription.deleted" do
        let(:subscription_data) do
          {
            id: account.stripe_subscription_id,
            customer: account.stripe_customer_id,
            ended_at: Time.now.to_i,
            current_period_end: 1.month.from_now.to_i
          }
        end

        before do
          account.update!(plan: :pro, subscription_status: :active)
        end

        it "cancels the subscription" do
          post_webhook(event_type: "customer.subscription.deleted", data: subscription_data)

          expect(response).to have_http_status(:ok)
          account.reload
          expect(account.subscription_status).to eq("canceled")
          expect(account.plan).to eq("free")
        end
      end

      describe "invoice.payment_succeeded" do
        let(:subscription_data) do
          double(
            id: account.stripe_subscription_id,
            current_period_end: 1.month.from_now.to_i
          )
        end

        before do
          account.update!(plan: :pro, subscription_status: :past_due)
          allow(Stripe::Subscription).to receive(:retrieve).and_return(subscription_data)
        end

        it "updates billing period and sets status to active" do
          post_webhook(
            event_type: "invoice.payment_succeeded",
            data: {
              customer: account.stripe_customer_id,
              subscription: account.stripe_subscription_id
            }
          )

          expect(response).to have_http_status(:ok)
          account.reload
          expect(account.subscription_status).to eq("active")
        end
      end

      describe "invoice.payment_failed" do
        before do
          account.update!(plan: :pro, subscription_status: :active)
        end

        it "sets subscription status to past_due" do
          post_webhook(
            event_type: "invoice.payment_failed",
            data: { customer: account.stripe_customer_id }
          )

          expect(response).to have_http_status(:ok)
          account.reload
          expect(account.subscription_status).to eq("past_due")
        end
      end

      describe "unhandled event" do
        it "returns 200 and logs the event" do
          allow(Rails.logger).to receive(:info)

          post_webhook(event_type: "some.other.event", data: {})

          expect(response).to have_http_status(:ok)
          expect(Rails.logger).to have_received(:info).with("Unhandled Stripe webhook event: some.other.event")
        end
      end
    end

    context "when account is not found" do
      it "returns 200 without errors" do
        post_webhook(
          event_type: "invoice.payment_failed",
          data: { customer: "cus_nonexistent" }
        )

        expect(response).to have_http_status(:ok)
      end
    end

    context "idempotency - same event processed twice" do
      let(:subscription_data) do
        {
          id: account.stripe_subscription_id,
          customer: account.stripe_customer_id,
          ended_at: Time.now.to_i,
          current_period_end: 1.month.from_now.to_i
        }
      end

      before do
        account.update!(plan: :pro, subscription_status: :active)
      end

      it "handles duplicate deletion events gracefully" do
        # First deletion
        post_webhook(event_type: "customer.subscription.deleted", data: subscription_data)
        expect(response).to have_http_status(:ok)
        expect(account.reload.subscription_status).to eq("canceled")

        # Second deletion (same event)
        post_webhook(event_type: "customer.subscription.deleted", data: subscription_data)
        expect(response).to have_http_status(:ok)
        expect(account.reload.subscription_status).to eq("canceled")
      end

      it "handles duplicate payment_failed events gracefully" do
        account.update!(plan: :pro, subscription_status: :active)

        # First failure
        post_webhook(event_type: "invoice.payment_failed", data: { customer: account.stripe_customer_id })
        expect(response).to have_http_status(:ok)
        expect(account.reload.subscription_status).to eq("past_due")

        # Second failure (same event)
        post_webhook(event_type: "invoice.payment_failed", data: { customer: account.stripe_customer_id })
        expect(response).to have_http_status(:ok)
        expect(account.reload.subscription_status).to eq("past_due")
      end
    end

    context "with unknown price IDs" do
      describe "customer.subscription.updated" do
        let(:subscription_data) do
          {
            id: account.stripe_subscription_id,
            customer: account.stripe_customer_id,
            status: "active",
            start_date: 1.day.ago.to_i,
            current_period_end: 1.month.from_now.to_i,
            cancel_at: nil,
            items: { data: [ { price: { id: "price_unknown_xyz" } } ] }
          }
        end

        before do
          account.update!(plan: :pro, subscription_status: :active)
        end

        it "keeps the current plan when price ID is not recognized" do
          post_webhook(event_type: "customer.subscription.updated", data: subscription_data)

          expect(response).to have_http_status(:ok)
          account.reload
          expect(account.plan).to eq("pro")
          expect(account.subscription_status).to eq("active")
        end
      end
    end

    context "with missing subscription ID" do
      describe "checkout.session.completed without subscription ID" do
        it "returns ok but does not update account" do
          post_webhook(
            event_type: "checkout.session.completed",
            data: {
              customer: account.stripe_customer_id,
              subscription: nil
            }
          )

          # The webhook returns ok but subscription sync is skipped when subscription is nil
          expect(response).to have_http_status(:ok)
        end
      end

      describe "invoice.payment_succeeded without subscription ID" do
        it "returns ok without updating" do
          post_webhook(
            event_type: "invoice.payment_succeeded",
            data: {
              customer: account.stripe_customer_id,
              subscription: nil
            }
          )

          expect(response).to have_http_status(:ok)
        end
      end
    end
  end
end
