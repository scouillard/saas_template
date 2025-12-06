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

      before { sign_in user }

      def build_mock_session(price_id:, trial_end:, current_period_end:, interval: "month")
        recurring = Struct.new(:interval).new(interval)
        price = Struct.new(:id, :recurring).new(price_id, recurring)
        item = Struct.new(:price).new(price)
        items = Struct.new(:data).new([ item ])
        subscription = Struct.new(:items, :trial_end, :current_period_end).new(items, trial_end, current_period_end)
        Struct.new(:subscription).new(subscription)
      end

      it "renders success page with subscription details" do
        mock_session = build_mock_session(
          price_id: "price_pro_monthly",
          trial_end: nil,
          current_period_end: 1.month.from_now.to_i
        )

        allow(Stripe::Checkout::Session).to receive(:retrieve)
          .with("cs_test123", expand: [ "subscription" ])
          .and_return(mock_session)

        get checkout_success_path, params: { session_id: "cs_test123" }

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Welcome to Pro!")
      end

      it "displays trial end date when subscription has trial" do
        trial_end = 14.days.from_now.to_i
        mock_session = build_mock_session(
          price_id: "price_pro_monthly",
          trial_end: trial_end,
          current_period_end: trial_end
        )

        allow(Stripe::Checkout::Session).to receive(:retrieve)
          .with("cs_test_trial", expand: [ "subscription" ])
          .and_return(mock_session)

        get checkout_success_path, params: { session_id: "cs_test_trial" }

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Trial ends")
      end

      it "redirects to pricing when session not found" do
        allow(Stripe::Checkout::Session).to receive(:retrieve)
          .and_raise(Stripe::InvalidRequestError.new("No such session", "session_id"))

        get checkout_success_path, params: { session_id: "invalid_session" }

        expect(response).to redirect_to(pricing_path)
        expect(flash[:alert]).to eq("Session not found")
      end
    end
  end
end
