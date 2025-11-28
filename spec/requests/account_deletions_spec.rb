require "rails_helper"

RSpec.describe "Account Deletions", type: :request do
  describe "DELETE /profile" do
    context "when user is a solo owner of their account" do
      let(:user) { create(:user) }

      before { sign_in user }

      it "deletes the user and their account" do
        account = user.accounts.first

        expect {
          delete profile_path
        }.to change(User, :count).by(-1)
          .and change(Account, :count).by(-1)

        expect(User.exists?(user.id)).to be false
        expect(Account.exists?(account.id)).to be false
      end

      it "signs out the user and redirects to root" do
        delete profile_path

        expect(response).to redirect_to(root_path)
        expect(controller.current_user).to be_nil
      end
    end

    context "when user is a regular member of another account" do
      let(:user) { create(:user) }
      let(:other_account) { create(:account) }

      before do
        create(:membership, user: user, account: other_account, role: :member)
        sign_in user
      end

      it "deletes the user and cleans up memberships" do
        user_account = user.accounts.first

        expect {
          delete profile_path
        }.to change(User, :count).by(-1)
          .and change(Membership, :count).by(-2)

        expect(other_account.reload).to be_present
      end
    end

    context "when user is an account manager (admin/owner) with other members" do
      let(:user) { create(:user) }
      let(:other_user) { create(:user) }

      before do
        user_account = user.accounts.first
        create(:membership, user: other_user, account: user_account, role: :member)
        sign_in user
      end

      it "does not delete the account and shows an error" do
        expect {
          delete profile_path
        }.not_to change(User, :count)

        expect(response).to redirect_to(profile_path)
        expect(flash[:alert]).to be_present
      end
    end
  end
end
