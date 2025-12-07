require "rails_helper"

RSpec.describe "StripeCheckout", type: :request do
  describe "POST /checkout" do
    context "when not signed in" do
      it "redirects to sign in page" do
        post checkout_path, params: { plan: "pro", interval: "monthly" }

        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when signed in" do
      let(:user) { create(:user) }
      let(:mock_session) { Struct.new(:url).new("https://checkout.stripe.com/test") }

      before { sign_in user }

      it "redirects to Stripe checkout session URL" do
        allow(Stripe::Checkout::Session).to receive(:create).and_return(mock_session)

        post checkout_path, params: { plan: "pro", interval: "monthly" }

        expect(response).to redirect_to("https://checkout.stripe.com/test")
        expect(response).to have_http_status(:see_other)
      end

      it "creates session with correct parameters for monthly billing" do
        allow(Stripe::Checkout::Session).to receive(:create).with(
          hash_including(
            line_items: [ { price: "price_pro_monthly", quantity: 1 } ],
            mode: "subscription",
            customer_email: user.email,
            allow_promotion_codes: true,
            automatic_tax: { enabled: true },
            subscription_data: { trial_period_days: 14 }
          )
        ).and_return(mock_session)

        post checkout_path, params: { plan: "pro", interval: "monthly" }

        expect(Stripe::Checkout::Session).to have_received(:create)
      end

      it "creates session with correct parameters for annual billing" do
        allow(Stripe::Checkout::Session).to receive(:create).with(
          hash_including(
            line_items: [ { price: "price_pro_annual", quantity: 1 } ]
          )
        ).and_return(mock_session)

        post checkout_path, params: { plan: "pro", interval: "annual" }

        expect(Stripe::Checkout::Session).to have_received(:create)
      end

      it "uses existing stripe_customer_id when available" do
        user.accounts.first.update!(stripe_customer_id: "cus_existing123")

        allow(Stripe::Checkout::Session).to receive(:create).with(
          hash_including(customer: "cus_existing123")
        ).and_return(mock_session)

        post checkout_path, params: { plan: "pro", interval: "monthly" }

        expect(Stripe::Checkout::Session).to have_received(:create)
      end

      it "redirects to pricing with error for invalid interval" do
        post checkout_path, params: { plan: "pro", interval: "invalid" }

        expect(response).to redirect_to(pricing_path)
        expect(flash[:alert]).to eq("Invalid billing interval")
      end

      it "redirects to pricing with error for plan without stripe price" do
        post checkout_path, params: { plan: "free", interval: "monthly" }

        expect(response).to redirect_to(pricing_path)
        expect(flash[:alert]).to eq("This plan is not available for purchase")
      end

      it "returns 404 for non-existent plan" do
        post checkout_path, params: { plan: "nonexistent", interval: "monthly" }

        expect(response).to have_http_status(:not_found)
      end

      context "when Stripe API raises InvalidRequestError" do
        before do
          allow(Stripe::Checkout::Session).to receive(:create)
            .and_raise(Stripe::InvalidRequestError.new("Invalid price", "price"))
        end

        it "raises the error (500)" do
          expect {
            post checkout_path, params: { plan: "pro", interval: "monthly" }
          }.to raise_error(Stripe::InvalidRequestError)
        end
      end

      context "when Stripe API raises StripeError" do
        before do
          allow(Stripe::Checkout::Session).to receive(:create)
            .and_raise(Stripe::StripeError.new("Stripe API error"))
        end

        it "raises the error" do
          expect {
            post checkout_path, params: { plan: "pro", interval: "monthly" }
          }.to raise_error(Stripe::StripeError)
        end
      end
    end

    context "rate limiting", :rate_limit do
      let(:user) { create(:user) }
      let(:mock_session) { Struct.new(:url).new("https://checkout.stripe.com/test") }

      before do
        sign_in user
        allow(Stripe::Checkout::Session).to receive(:create).and_return(mock_session)
        # Clear rate limit cache before each test
        Rails.cache.clear
      end

      it "blocks requests exceeding rate limit" do
        11.times do
          post checkout_path, params: { plan: "pro", interval: "monthly" }
        end

        expect(response).to have_http_status(:too_many_requests)
      end
    end
  end
end
