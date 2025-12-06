require "rails_helper"

RSpec.describe "CheckoutSuccess", type: :request do
  describe "GET /checkout/success" do
    context "when not signed in" do
      it "redirects to sign in page" do
        get checkout_success_path, params: { session_id: "cs_test123" }

        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when signed in" do
      let(:user) { create(:user) }
      let(:account) { user.accounts.first }

      before { sign_in user }

      def build_mock_session(price_id:, current_period_end:, status: "complete", subscription_id: "sub_123", created: Time.current.to_i)
        recurring = Struct.new(:interval).new("month")
        price = Struct.new(:id, :recurring).new(price_id, recurring)
        item = Struct.new(:price).new(price)
        items = Struct.new(:data).new([ item ])
        subscription = Struct.new(:id, :items, :status, :created, :current_period_end).new(
          subscription_id, items, "active", created, current_period_end
        )
        customer = Struct.new(:id).new("cus_123")
        Struct.new(:subscription, :customer, :status).new(subscription, customer, status)
      end

      it "redirects to root with success notice after processing subscription" do
        mock_session = build_mock_session(
          price_id: "price_pro_monthly",
          current_period_end: 1.month.from_now.to_i
        )

        allow(Stripe::Checkout::Session).to receive(:retrieve)
          .with("cs_test123", expand: [ "subscription", "customer" ])
          .and_return(mock_session)

        get checkout_success_path, params: { session_id: "cs_test123" }

        expect(response).to redirect_to(root_path)
        expect(flash[:notice]).to include("Your subscription is now active")
      end

      it "redirects to pricing when payment incomplete" do
        mock_session = build_mock_session(
          price_id: "price_pro_monthly",
          current_period_end: 1.month.from_now.to_i,
          status: "open"
        )

        allow(Stripe::Checkout::Session).to receive(:retrieve)
          .with("cs_test_incomplete", expand: [ "subscription", "customer" ])
          .and_return(mock_session)

        get checkout_success_path, params: { session_id: "cs_test_incomplete" }

        expect(response).to redirect_to(pricing_path)
        expect(flash[:alert]).to eq("Payment incomplete. Please try again.")
      end

      it "redirects to pricing when session not found" do
        allow(Stripe::Checkout::Session).to receive(:retrieve)
          .and_raise(Stripe::InvalidRequestError.new("No such session", "session_id"))

        get checkout_success_path, params: { session_id: "invalid_session" }

        expect(response).to redirect_to(pricing_path)
        expect(flash[:alert]).to eq("Checkout session not found")
      end
    end
  end
end
