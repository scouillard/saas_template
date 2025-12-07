require "rails_helper"

RSpec.describe "BillingPortal", type: :request do
  describe "POST /billing_portal" do
    context "when not signed in" do
      it "redirects to sign in page" do
        post billing_portal_path

        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when signed in" do
      let(:user) { create(:user) }

      before { sign_in user }

      context "without stripe_customer_id" do
        it "redirects to billing page with alert" do
          post billing_portal_path

          expect(response).to redirect_to(billing_path)
          expect(flash[:alert]).to eq("Please subscribe to a plan first")
        end
      end

      context "with stripe_customer_id" do
        let(:mock_session) { Struct.new(:url).new("https://billing.stripe.com/session/test") }

        before do
          user.accounts.first.update!(stripe_customer_id: "cus_test123")
        end

        it "redirects to Stripe Billing Portal URL" do
          allow(Stripe::BillingPortal::Session).to receive(:create).and_return(mock_session)

          post billing_portal_path

          expect(response).to redirect_to("https://billing.stripe.com/session/test")
          expect(response).to have_http_status(:see_other)
        end

        it "creates session with correct parameters" do
          allow(Stripe::BillingPortal::Session).to receive(:create).with(
            hash_including(
              customer: "cus_test123",
              return_url: billing_url
            )
          ).and_return(mock_session)

          post billing_portal_path

          expect(Stripe::BillingPortal::Session).to have_received(:create)
        end
      end
    end
  end
end
