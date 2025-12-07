require "rails_helper"

RSpec.describe "PlanChanges", type: :request do
  describe "GET /plan_changes/new" do
    context "when not signed in" do
      it "redirects to sign in page" do
        get new_plan_change_path(plan: "enterprise")
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when signed in without active subscription" do
      let(:user) { create(:user) }

      before { sign_in user }

      it "redirects to pricing page" do
        get new_plan_change_path(plan: "enterprise")
        expect(response).to redirect_to(pricing_path)
        expect(flash[:alert]).to eq("You need an active subscription to change plans")
      end
    end

    context "when signed in with active subscription" do
      let(:user) { create(:user) }
      let(:account) { user.accounts.first }

      before do
        sign_in user
        account.update!(
          plan: "pro",
          subscription_status: "active",
          stripe_customer_id: "cus_test123",
          stripe_subscription_id: "sub_test123"
        )
      end

      it "displays plan comparison page" do
        get new_plan_change_path(plan: "enterprise", interval: "monthly")
        expect(response).to have_http_status(:ok)
      end

      it "redirects when selecting same plan" do
        get new_plan_change_path(plan: "pro")
        expect(response).to redirect_to(plan_path)
        expect(flash[:alert]).to eq("You're already on this plan")
      end

      it "redirects when plan not found" do
        get new_plan_change_path(plan: "nonexistent")
        expect(response).to redirect_to(plan_path)
      end
    end
  end

  describe "POST /plan_changes" do
    context "when not signed in" do
      it "redirects to sign in page" do
        post plan_changes_path, params: { plan: "enterprise", interval: "monthly" }
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when signed in with active subscription" do
      let(:user) { create(:user) }
      let(:account) { user.accounts.first }
      let(:mock_session) { Struct.new(:url).new("https://checkout.stripe.com/test") }

      before do
        sign_in user
        account.update!(
          plan: "pro",
          subscription_status: "active",
          stripe_customer_id: "cus_test123",
          stripe_subscription_id: "sub_test123"
        )
      end

      it "redirects to Stripe checkout session URL" do
        allow(Stripe::Checkout::Session).to receive(:create).and_return(mock_session)

        post plan_changes_path, params: { plan: "enterprise", interval: "monthly" }

        expect(response).to redirect_to("https://checkout.stripe.com/test")
        expect(response).to have_http_status(:see_other)
      end

      it "creates session with existing customer ID" do
        allow(Stripe::Checkout::Session).to receive(:create).with(
          hash_including(customer: "cus_test123")
        ).and_return(mock_session)

        post plan_changes_path, params: { plan: "enterprise", interval: "monthly" }

        expect(Stripe::Checkout::Session).to have_received(:create)
      end

      it "creates session with correct price for monthly billing" do
        allow(Stripe::Checkout::Session).to receive(:create).with(
          hash_including(
            line_items: [ { price: "price_enterprise_monthly", quantity: 1 } ]
          )
        ).and_return(mock_session)

        post plan_changes_path, params: { plan: "enterprise", interval: "monthly" }

        expect(Stripe::Checkout::Session).to have_received(:create)
      end

      it "creates session with correct price for annual billing" do
        allow(Stripe::Checkout::Session).to receive(:create).with(
          hash_including(
            line_items: [ { price: "price_enterprise_annual", quantity: 1 } ]
          )
        ).and_return(mock_session)

        post plan_changes_path, params: { plan: "enterprise", interval: "annual" }

        expect(Stripe::Checkout::Session).to have_received(:create)
      end

      it "redirects with error for invalid interval" do
        post plan_changes_path, params: { plan: "enterprise", interval: "invalid" }

        expect(response).to redirect_to(new_plan_change_path(plan: "enterprise"))
        expect(flash[:alert]).to eq("Invalid billing interval")
      end

      it "redirects when selecting same plan" do
        post plan_changes_path, params: { plan: "pro", interval: "monthly" }
        expect(response).to redirect_to(plan_path)
      end
    end

    context "when downgrading" do
      let(:user) { create(:user) }
      let(:account) { user.accounts.first }
      let(:mock_session) { Struct.new(:url).new("https://checkout.stripe.com/test") }

      before do
        sign_in user
        account.update!(
          plan: "enterprise",
          subscription_status: "active",
          stripe_customer_id: "cus_test123",
          stripe_subscription_id: "sub_test123"
        )
      end

      it "creates checkout session for downgrade" do
        allow(Stripe::Checkout::Session).to receive(:create).with(
          hash_including(
            line_items: [ { price: "price_pro_monthly", quantity: 1 } ]
          )
        ).and_return(mock_session)

        post plan_changes_path, params: { plan: "pro", interval: "monthly" }

        expect(Stripe::Checkout::Session).to have_received(:create)
        expect(response).to redirect_to("https://checkout.stripe.com/test")
      end
    end
  end
end
