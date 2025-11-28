require "rails_helper"

RSpec.describe "Stripe", type: :request do
  let(:user) { create(:user) }
  let(:account) { user.accounts.first }

  before do
    sign_in user
  end

  describe "POST /stripe/checkout" do
    let(:price_id) { "price_test123" }
    let(:checkout_session) do
      double(
        "Stripe::Checkout::Session",
        id: "cs_test_abc123",
        url: "https://checkout.stripe.com/c/pay/cs_test_abc123"
      )
    end

    before do
      allow(Stripe::Checkout::Session).to receive(:create).and_return(checkout_session)
    end

    it "creates a checkout session and redirects to Stripe" do
      post stripe_checkout_path, params: { price_id: price_id }

      expect(Stripe::Checkout::Session).to have_received(:create).with(
        hash_including(
          mode: "subscription",
          line_items: [{ price: price_id, quantity: 1 }]
        )
      )
      expect(response).to redirect_to(checkout_session.url)
    end
  end

  describe "GET /stripe/success" do
    it "renders success page" do
      get stripe_success_path

      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /stripe/cancel" do
    it "redirects to plans page" do
      get stripe_cancel_path

      expect(response).to redirect_to(plan_path)
    end
  end

  describe "POST /stripe/webhook" do
    let(:payload) { { type: "checkout.session.completed" }.to_json }
    let(:signature) { "test_signature" }
    let(:event) do
      double(
        "Stripe::Event",
        type: "checkout.session.completed",
        data: double(object: checkout_session_object)
      )
    end
    let(:checkout_session_object) do
      double(
        customer: "cus_test123",
        subscription: "sub_test456",
        metadata: { "account_id" => account.id.to_s }
      )
    end

    before do
      allow(Stripe::Webhook).to receive(:construct_event).and_return(event)
    end

    it "processes checkout.session.completed event" do
      post stripe_webhook_path,
           params: payload,
           headers: { "Stripe-Signature" => signature, "CONTENT_TYPE" => "application/json" }

      expect(response).to have_http_status(:ok)
      account.reload
      expect(account.stripe_customer_id).to eq("cus_test123")
      expect(account.stripe_subscription_id).to eq("sub_test456")
    end
  end
end
