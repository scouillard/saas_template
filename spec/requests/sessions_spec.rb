require "rails_helper"

RSpec.describe "Sessions", type: :request do
  describe "POST /users/sign_in" do
    let(:user) { create(:user) }

    it "redirects to root path after sign in" do
      post user_session_path, params: {
        user: { email: user.email, password: "password123" }
      }

      expect(response).to redirect_to(root_path)
    end
  end

  describe "DELETE /users/sign_out" do
    let(:user) { create(:user) }

    before { sign_in user }

    it "signs out the user" do
      delete destroy_user_session_path

      expect(controller.current_user).to be_nil
    end
  end
end
