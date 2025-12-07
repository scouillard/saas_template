require "rails_helper"

RSpec.describe "Subscriptions", type: :request do
  describe "GET /subscription/cancel" do
    context "when not signed in" do
      it "redirects to sign in page" do
        get cancel_subscription_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when signed in" do
      let(:user) { create(:user) }

      before { sign_in user }

      context "with active subscription" do
        before do
          user.accounts.first.update!(
            subscription_status: :active,
            current_period_ends_at: 1.month.from_now
          )
        end

        it "renders the cancel page" do
          get cancel_subscription_path
          expect(response).to have_http_status(:ok)
        end
      end

      context "without active subscription" do
        before do
          user.accounts.first.update!(subscription_status: :canceled)
        end

        it "redirects to plan page with alert" do
          get cancel_subscription_path
          expect(response).to redirect_to(plan_path)
          expect(flash[:alert]).to eq("No active subscription to cancel")
        end
      end
    end
  end

  describe "POST /subscription/portal" do
    context "when not signed in" do
      it "redirects to sign in page" do
        post subscription_portal_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when signed in" do
      let(:user) { create(:user) }

      before { sign_in user }

      context "with stripe customer id" do
        let(:mock_session) { Struct.new(:url).new("https://billing.stripe.com/test") }

        before do
          user.accounts.first.update!(stripe_customer_id: "cus_test123")
        end

        it "redirects to Stripe billing portal" do
          allow(Stripe::BillingPortal::Session).to receive(:create).and_return(mock_session)

          post subscription_portal_path

          expect(response).to redirect_to("https://billing.stripe.com/test")
          expect(response).to have_http_status(:see_other)
        end
      end

      context "without stripe customer id" do
        it "redirects to plan page with alert" do
          post subscription_portal_path
          expect(response).to redirect_to(plan_path)
          expect(flash[:alert]).to eq("No billing information found")
        end
      end
    end
  end

  describe "POST /subscription/reactivate" do
    context "when not signed in" do
      it "redirects to sign in page" do
        post reactivate_subscription_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when signed in" do
      let(:user) { create(:user) }

      before { sign_in user }

      context "with canceling subscription" do
        before do
          user.accounts.first.update!(
            subscription_status: :canceling,
            stripe_subscription_id: "sub_test123",
            current_period_ends_at: 1.month.from_now
          )
        end

        it "reactivates the subscription" do
          allow(Stripe::Subscription).to receive(:update)

          post reactivate_subscription_path

          expect(Stripe::Subscription).to have_received(:update).with(
            "sub_test123",
            cancel_at_period_end: false
          )
          expect(user.accounts.first.reload.subscription_status).to eq("active")
          expect(response).to redirect_to(plan_path)
          expect(flash[:notice]).to eq("Your subscription has been reactivated")
        end
      end

      context "without canceling subscription" do
        before do
          user.accounts.first.update!(subscription_status: :active)
        end

        it "redirects with alert" do
          post reactivate_subscription_path
          expect(response).to redirect_to(plan_path)
          expect(flash[:alert]).to eq("Cannot reactivate subscription")
        end
      end

      context "with expired period" do
        before do
          user.accounts.first.update!(
            subscription_status: :canceling,
            current_period_ends_at: 1.day.ago
          )
        end

        it "redirects with alert" do
          post reactivate_subscription_path
          expect(response).to redirect_to(plan_path)
          expect(flash[:alert]).to eq("Cannot reactivate subscription")
        end
      end
    end
  end
end
