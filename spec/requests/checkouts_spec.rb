require "rails_helper"

RSpec.describe "Checkouts", type: :request do
  let(:user) { create(:user) }
  let(:account) { user.accounts.first }
  let(:session_id) { "cs_test_123" }
  let(:subscription_id) { "sub_test_456" }
  let(:customer_id) { "cus_test_789" }
  let(:mock_session) { build_mock_session(status: "complete") }

  before do
    post user_session_path, params: { user: { email: user.email, password: "password123" } }
  end

  def build_mock_session(status:, trial_end: nil)
    mock_recurring = Struct.new(:interval).new("month")
    mock_price = Struct.new(:id, :recurring).new("price_pro_monthly", mock_recurring)
    mock_item = Struct.new(:price).new(mock_price)
    mock_items = Struct.new(:data).new([ mock_item ])
    mock_subscription = Struct.new(:id, :status, :created, :current_period_end, :items, :trial_end).new(
      subscription_id, "active", 1.day.ago.to_i, 1.month.from_now.to_i, mock_items, trial_end
    )
    Struct.new(:status, :customer, :subscription).new(status, customer_id, mock_subscription)
  end

  describe "GET /checkout/success" do
    context "with valid session" do
      before { allow(Stripe::Checkout::Session).to receive(:retrieve).and_return(mock_session) }

      it "updates account with stripe customer id" do
        get checkout_success_path, params: { session_id: session_id }
        expect(account.reload.stripe_customer_id).to eq(customer_id)
      end

      it "updates account with subscription id" do
        get checkout_success_path, params: { session_id: session_id }
        expect(account.reload.stripe_subscription_id).to eq(subscription_id)
      end

      it "updates account subscription status" do
        get checkout_success_path, params: { session_id: session_id }
        expect(account.reload.subscription_status).to eq("active")
      end

      it "updates account plan to pro" do
        get checkout_success_path, params: { session_id: session_id }
        expect(account.reload.plan).to eq("pro")
      end

      it "renders success page with subscription details" do
        get checkout_success_path, params: { session_id: session_id }

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Welcome to Pro!")
      end
    end

    context "when session already processed" do
      before do
        account.update!(stripe_subscription_id: subscription_id)
        allow(Stripe::Checkout::Session).to receive(:retrieve).and_return(mock_session)
      end

      it "redirects with already active notice" do
        get checkout_success_path, params: { session_id: session_id }

        expect(response).to redirect_to(root_path)
        follow_redirect!
        expect(response.body).to include("Subscription already active")
      end

      it "does not update account" do
        expect {
          get checkout_success_path, params: { session_id: session_id }
        }.not_to change { account.reload.updated_at }
      end
    end

    context "when session_id is missing" do
      it "redirects to pricing with alert" do
        get checkout_success_path

        expect(response).to redirect_to(pricing_path)
        follow_redirect!
        expect(response.body).to include("Invalid checkout session")
      end
    end

    context "when session is invalid" do
      before do
        allow(Stripe::Checkout::Session).to receive(:retrieve).and_return(nil)
      end

      it "redirects to pricing with alert" do
        get checkout_success_path, params: { session_id: "invalid_session" }

        expect(response).to redirect_to(pricing_path)
        follow_redirect!
        expect(response.body).to include("Checkout session not found")
      end
    end

    context "when payment is incomplete" do
      let(:mock_session) { build_mock_session(status: "open") }

      before { allow(Stripe::Checkout::Session).to receive(:retrieve).and_return(mock_session) }

      it "redirects to pricing with alert" do
        get checkout_success_path, params: { session_id: session_id }

        expect(response).to redirect_to(pricing_path)
        follow_redirect!
        expect(response.body).to include("Payment incomplete")
      end
    end
  end
end
