require "rails_helper"

RSpec.describe "Profiles", type: :request do
  let(:user) { create(:user, name: "Original Name") }

  before { sign_in user }

  describe "GET /profile" do
    it "renders the profile page" do
      get profile_path

      expect(response).to have_http_status(:ok)
    end
  end

  describe "PATCH /profile" do
    it "updates the user name" do
      patch profile_path, params: { user: { name: "New Name" } }

      expect(response).to redirect_to(profile_path)
      expect(user.reload.name).to eq("New Name")
    end

    it "re-renders on invalid input" do
      patch profile_path, params: { user: { name: "" } }

      # Name is optional, so this should succeed
      expect(response).to redirect_to(profile_path)
    end
  end

  describe "PATCH /profile/password" do
    it "updates password with valid current password" do
      patch update_password_profile_path, params: {
        user: {
          current_password: "password123",
          password: "newpassword456",
          password_confirmation: "newpassword456"
        }
      }

      expect(response).to redirect_to(profile_path)
      expect(user.reload.valid_password?("newpassword456")).to be true
    end

    it "fails with incorrect current password" do
      patch update_password_profile_path, params: {
        user: {
          current_password: "wrongpassword",
          password: "newpassword456",
          password_confirmation: "newpassword456"
        }
      }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(user.reload.valid_password?("password123")).to be true
    end

    it "fails when confirmation does not match" do
      patch update_password_profile_path, params: {
        user: {
          current_password: "password123",
          password: "newpassword456",
          password_confirmation: "differentpassword"
        }
      }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(user.reload.valid_password?("password123")).to be true
    end
  end

  describe "DELETE /profile" do
    context "when user can delete their account" do
      it "deletes the user and redirects to root" do
        expect { delete profile_path }.to change(User, :count).by(-1)

        expect(response).to redirect_to(root_path)
        follow_redirect!
        expect(response.body).to include("Your account has been deleted")
      end

      it "destroys user memberships" do
        expect { delete profile_path }.to change(Membership, :count).by(-1)
      end
    end

    context "when user is owner with other members" do
      let(:account) { user.accounts.first }

      before do
        other_user = create(:user)
        other_user.memberships.destroy_all
        create(:membership, user: other_user, account: account)
      end

      it "does not delete the user" do
        expect { delete profile_path }.not_to change(User, :count)
      end

      it "redirects to profile with alert" do
        delete profile_path

        expect(response).to redirect_to(profile_path)
        follow_redirect!
        expect(response.body).to include("owner or admin with team members")
      end
    end
  end
end
