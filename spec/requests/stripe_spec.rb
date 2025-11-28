require "rails_helper"

RSpec.describe "Stripe", type: :request do
  let(:user) { create(:user) }
  let(:account) { create(:account) }

  def sign_in_user
    post user_session_path, params: { user: { email: user.email, password: "password123" } }
  end

  before do
    create(:membership, user: user, account: account)
  end

  describe "POST /stripe/checkout" do
    context "with valid price_id" do
      let(:price_id) { "price_test123" }
      let(:checkout_session) do
        double(
          "Stripe::Checkout::Session",
          url: "https://checkout.stripe.com/session123"
        )
      end

      before do
        sign_in_user
        allow(Stripe::Customer).to receive(:create).and_return(
          double("Stripe::Customer", id: "cus_test123")
        )
        allow(Stripe::Checkout::Session).to receive(:create).and_return(checkout_session)
      end

      it "creates a checkout session and redirects" do
        post stripe_checkout_path, params: { price_id: price_id }

        expect(response).to redirect_to("https://checkout.stripe.com/session123")
      end

      it "creates a Stripe customer if not exists" do
        expect(Stripe::Customer).to receive(:create).with(
          hash_including(email: user.email)
        )

        post stripe_checkout_path, params: { price_id: price_id }
      end
    end

    context "without price_id" do
      before { sign_in_user }

      it "redirects to plan path with alert" do
        post stripe_checkout_path, params: { price_id: "" }

        expect(response).to redirect_to(plan_path)
        expect(flash[:alert]).to eq("Invalid price")
      end
    end

    context "when not authenticated" do
      it "redirects to sign in" do
        post stripe_checkout_path, params: { price_id: "price_test" }

        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "GET /stripe/success" do
    let(:session_id) { "cs_test123" }
    let(:subscription) do
      double(
        "Stripe::Subscription",
        id: "sub_test123",
        current_period_start: Time.current.to_i,
        current_period_end: 1.month.from_now.to_i,
        items: double(data: [ double(price: double(id: "price_pro")) ])
      )
    end

    before do
      sign_in_user
      allow(Stripe::Checkout::Session).to receive(:retrieve).and_return(
        double("Stripe::Checkout::Session", subscription: "sub_test123")
      )
      allow(Stripe::Subscription).to receive(:retrieve).and_return(subscription)
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("STRIPE_PRO_PRICE_ID").and_return("price_pro")
    end

    it "updates the account with subscription details" do
      get stripe_success_path, params: { session_id: session_id }

      # Reload the user's first account (which is what current_account returns)
      updated_account = user.accounts.first
      expect(updated_account.stripe_subscription_id).to eq("sub_test123")
      expect(updated_account.subscription_active?).to be true
      expect(updated_account.pro?).to be true
    end

    it "redirects to plan path with success notice" do
      get stripe_success_path, params: { session_id: session_id }

      expect(response).to redirect_to(plan_path)
      expect(flash[:notice]).to eq("Subscription activated successfully!")
    end
  end

  describe "GET /stripe/cancel" do
    before { sign_in_user }

    it "redirects to plan path with notice" do
      get stripe_cancel_path

      expect(response).to redirect_to(plan_path)
      expect(flash[:notice]).to eq("Checkout was canceled.")
    end
  end

  describe "POST /stripe/webhook" do
    let(:webhook_secret) { "whsec_test123" }
    let(:payload) { { type: "customer.subscription.created" }.to_json }
    let(:sig_header) { "t=12345,v1=abc123" }

    before do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("STRIPE_WEBHOOK_SECRET").and_return(webhook_secret)
    end

    context "with valid signature" do
      let(:subscription_event) do
        double(
          "Stripe::Event",
          type: "customer.subscription.updated",
          data: double(
            object: double(
              id: "sub_test123",
              customer: account.stripe_customer_id,
              status: "active",
              current_period_start: Time.current.to_i,
              current_period_end: 1.month.from_now.to_i,
              items: double(data: [ double(price: double(id: "price_pro")) ])
            )
          )
        )
      end

      before do
        account.update!(stripe_customer_id: "cus_test123")
        allow(Stripe::Webhook).to receive(:construct_event).and_return(subscription_event)
        allow(ENV).to receive(:[]).with("STRIPE_PRO_PRICE_ID").and_return("price_pro")
      end

      it "handles subscription updated event" do
        post stripe_webhook_path,
             params: payload,
             headers: { "HTTP_STRIPE_SIGNATURE" => sig_header, "CONTENT_TYPE" => "application/json" }

        expect(response).to have_http_status(:ok)
        account.reload
        expect(account.stripe_subscription_id).to eq("sub_test123")
        expect(account.subscription_active?).to be true
      end
    end

    context "with subscription deleted event" do
      let(:deleted_event) do
        double(
          "Stripe::Event",
          type: "customer.subscription.deleted",
          data: double(
            object: double(
              customer: account.stripe_customer_id
            )
          )
        )
      end

      before do
        account.update!(
          stripe_customer_id: "cus_test123",
          stripe_subscription_id: "sub_test123",
          subscription_status: :active,
          plan: :pro
        )
        allow(Stripe::Webhook).to receive(:construct_event).and_return(deleted_event)
      end

      it "cancels the subscription" do
        post stripe_webhook_path,
             params: payload,
             headers: { "HTTP_STRIPE_SIGNATURE" => sig_header, "CONTENT_TYPE" => "application/json" }

        expect(response).to have_http_status(:ok)
        account.reload
        expect(account.subscription_canceled?).to be true
        expect(account.free?).to be true
      end
    end

    context "with invalid signature" do
      before do
        allow(Stripe::Webhook).to receive(:construct_event)
          .and_raise(Stripe::SignatureVerificationError.new("Invalid", sig_header))
      end

      it "returns bad request" do
        post stripe_webhook_path,
             params: payload,
             headers: { "HTTP_STRIPE_SIGNATURE" => sig_header, "CONTENT_TYPE" => "application/json" }

        expect(response).to have_http_status(:bad_request)
      end
    end

    context "with invalid JSON" do
      before do
        allow(Stripe::Webhook).to receive(:construct_event)
          .and_raise(JSON::ParserError.new("Invalid JSON"))
      end

      it "returns bad request" do
        post stripe_webhook_path,
             params: "invalid json",
             headers: { "HTTP_STRIPE_SIGNATURE" => sig_header, "CONTENT_TYPE" => "application/json" }

        expect(response).to have_http_status(:bad_request)
      end
    end
  end
end
