require "rails_helper"

RSpec.describe "StripeWebhooks", type: :request do
  let(:webhook_secret) { "whsec_test_secret" }

  before do
    allow(Rails.application.credentials).to receive(:dig).with(:stripe, :webhook_secret).and_return(webhook_secret)
  end

  describe "POST /webhooks/stripe" do
    let(:account) { create(:account, :with_stripe, subscription_status: :active) }
    let(:headers) { { "HTTP_STRIPE_SIGNATURE" => "t=123,v1=test", "CONTENT_TYPE" => "application/json" } }

    context "with invalid signature" do
      it "returns bad request" do
        allow(Stripe::Webhook).to receive(:construct_event).and_raise(Stripe::SignatureVerificationError.new("Invalid signature", "sig"))

        post webhooks_stripe_path,
             params: { type: "test" }.to_json,
             headers: headers

        expect(response).to have_http_status(:bad_request)
      end
    end

    context "customer.subscription.updated event" do
      let(:event_object) do
        {
          id: account.stripe_subscription_id,
          cancel_at_period_end: true,
          current_period_end: 1.month.from_now.to_i,
          status: "active"
        }
      end

      it "updates account to canceling when cancel_at_period_end is true" do
        event = Stripe::Event.construct_from(
          type: "customer.subscription.updated",
          data: { object: event_object }
        )
        allow(Stripe::Webhook).to receive(:construct_event).and_return(event)

        post webhooks_stripe_path,
             params: {}.to_json,
             headers: headers

        expect(response).to have_http_status(:ok)
        expect(account.reload.subscription_status).to eq("canceling")
      end

      context "when cancel_at_period_end is false" do
        let(:event_object) do
          {
            id: account.stripe_subscription_id,
            cancel_at_period_end: false,
            current_period_end: 1.month.from_now.to_i,
            status: "active"
          }
        end

        it "updates account status to the subscription status" do
          event = Stripe::Event.construct_from(
            type: "customer.subscription.updated",
            data: { object: event_object }
          )
          allow(Stripe::Webhook).to receive(:construct_event).and_return(event)

          post webhooks_stripe_path,
               params: {}.to_json,
               headers: headers

          expect(response).to have_http_status(:ok)
          expect(account.reload.subscription_status).to eq("active")
        end
      end
    end

    context "customer.subscription.deleted event" do
      let(:event_object) { { id: account.stripe_subscription_id } }

      before do
        account.update!(plan: :pro)
      end

      it "downgrades account to free plan" do
        event = Stripe::Event.construct_from(
          type: "customer.subscription.deleted",
          data: { object: event_object }
        )
        allow(Stripe::Webhook).to receive(:construct_event).and_return(event)

        post webhooks_stripe_path,
             params: {}.to_json,
             headers: headers

        expect(response).to have_http_status(:ok)
        account.reload
        expect(account.subscription_status).to eq("canceled")
        expect(account.plan).to eq("free")
        expect(account.stripe_subscription_id).to be_nil
      end
    end

    context "with unknown account" do
      let(:event_object) do
        {
          id: "sub_unknown",
          cancel_at_period_end: true,
          current_period_end: 1.month.from_now.to_i
        }
      end

      it "returns ok without updating anything" do
        event = Stripe::Event.construct_from(
          type: "customer.subscription.updated",
          data: { object: event_object }
        )
        allow(Stripe::Webhook).to receive(:construct_event).and_return(event)

        post webhooks_stripe_path,
             params: {}.to_json,
             headers: headers

        expect(response).to have_http_status(:ok)
      end
    end
  end
end
