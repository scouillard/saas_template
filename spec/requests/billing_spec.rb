require "rails_helper"

RSpec.describe "Billing", type: :request do
  describe "GET /billing" do
    context "when not signed in" do
      it "redirects to sign in page" do
        get billing_path

        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when signed in" do
      let(:user) { create(:user) }

      before { sign_in user }

      it "returns successful response" do
        get billing_path

        expect(response).to have_http_status(:ok)
      end

      it "displays current plan" do
        get billing_path

        expect(response.body).to include("Current Plan")
      end
    end
  end
end
